import re
from django.conf import settings
from django.contrib.auth.models import User
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.utils import timezone
from .models import HealthSnapshot, MedicalDocument, FoodIntake, DocumentAnalysis
from .serializers import (
    RegisterSerializer, UserSerializer, UserProfileSerializer,
    HealthSnapshotSerializer, MedicalDocumentSerializer, FoodIntakeSerializer,
)


class ChangePasswordView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        old_password = request.data.get('old_password', '')
        new_password = request.data.get('new_password', '')

        if not old_password or not new_password:
            return Response({'detail': 'Both old_password and new_password are required.'},
                            status=status.HTTP_400_BAD_REQUEST)
        if not request.user.check_password(old_password):
            return Response({'old_password': 'Current password is incorrect.'},
                            status=status.HTTP_400_BAD_REQUEST)
        if len(new_password) < 8:
            return Response({'new_password': 'Password must be at least 8 characters.'},
                            status=status.HTTP_400_BAD_REQUEST)

        request.user.set_password(new_password)
        request.user.save()
        return Response({'detail': 'Password updated successfully.'})


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class AvatarUploadView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def patch(self, request):
        profile = request.user.profile
        file = request.FILES.get('avatar')
        if not file:
            return Response({'error': 'No file provided'},
                            status=status.HTTP_400_BAD_REQUEST)
        profile.avatar = file
        profile.save()
        serializer = UserProfileSerializer(profile)
        return Response(serializer.data)


# NL-28 / NL-31 — Health history & baseline
class HealthSnapshotListView(generics.ListCreateAPIView):
    serializer_class = HealthSnapshotSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = HealthSnapshot.objects.filter(user=self.request.user)
        limit = self.request.query_params.get('limit')
        if limit:
            try:
                qs = qs[:int(limit)]
            except (ValueError, TypeError):
                pass
        return qs

    def list(self, request, *args, **kwargs):
        response = super().list(request, *args, **kwargs)
        # Inject target_weight derived from healthy BMI (22.5) and profile height
        profile = getattr(request.user, 'profile', None)
        target_weight = None
        if profile and profile.height:
            target_weight = round(22.5 * (profile.height / 100) ** 2, 1)
        response.data = {
            'snapshots': response.data,
            'target_weight': target_weight,
        }
        return response

    def perform_create(self, serializer):
        # Auto-fill bmi and calorie target from current profile if not provided
        profile = self.request.user.profile
        serializer.save(
            user=self.request.user,
            bmi=serializer.validated_data.get('bmi') or profile.bmi,
            daily_calorie_target=(
                serializer.validated_data.get('daily_calorie_target')
                or profile.daily_calorie_target
            ),
        )


# NL-29 / NL-30 — Medical documents
class MedicalDocumentListView(generics.ListAPIView):
    serializer_class = MedicalDocumentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return MedicalDocument.objects.filter(user=self.request.user)


def _analyze_document(document):
    """Extract medical values from a document using Groq. Runs synchronously."""
    import base64, json, mimetypes
    api_key = settings.GROQ_API_KEY
    if not api_key:
        return

    file_path = document.file.path
    mime, _ = mimetypes.guess_type(file_path)

    system_prompt = (
        "You are a medical document analyzer. Extract biomarker values and return ONLY valid JSON "
        "with this exact structure (use null for missing values):\n"
        '{"blood_glucose":null,"hba1c":null,"cholesterol_total":null,"cholesterol_ldl":null,'
        '"cholesterol_hdl":null,"triglycerides":null,"blood_pressure_systolic":null,'
        '"blood_pressure_diastolic":null,"vitamin_d":null,"vitamin_b12":null,"ferritin":null,'
        '"summary":"one sentence summary","key_findings":[],"dietary_recommendations":[]}'
    )

    try:
        from groq import Groq
        client = Groq(api_key=api_key)

        if mime and mime.startswith('image/'):
            with open(file_path, 'rb') as f:
                b64 = base64.b64encode(f.read()).decode()
            messages = [{'role': 'user', 'content': [
                {'type': 'image_url', 'image_url': {'url': f'data:{mime};base64,{b64}'}},
                {'type': 'text', 'text': 'Extract all medical biomarker values from this document.'}
            ]}]
            model = 'meta-llama/llama-4-scout-17b-16e-instruct'
        else:
            # PDF or text — extract text
            text = ''
            if file_path.endswith('.pdf'):
                try:
                    from pypdf import PdfReader
                    reader = PdfReader(file_path)
                    text = '\n'.join(p.extract_text() or '' for p in reader.pages)
                except Exception:
                    text = 'Could not extract PDF text.'
            else:
                with open(file_path, 'r', errors='ignore') as f:
                    text = f.read()
            messages = [{'role': 'user', 'content': f'Extract medical values from:\n{text[:4000]}'}]
            model = 'llama-3.1-8b-instant'

        completion = client.chat.completions.create(
            model=model,
            messages=[{'role': 'system', 'content': system_prompt}] + messages,
            max_tokens=800,
            temperature=0.1,
        )
        raw = completion.choices[0].message.content.strip()
        # Extract JSON block
        start = raw.find('{')
        end = raw.rfind('}') + 1
        data = json.loads(raw[start:end]) if start != -1 else {}

        DocumentAnalysis.objects.update_or_create(
            document=document,
            defaults={
                'blood_glucose':             data.get('blood_glucose'),
                'hba1c':                     data.get('hba1c'),
                'cholesterol_total':         data.get('cholesterol_total'),
                'cholesterol_ldl':           data.get('cholesterol_ldl'),
                'cholesterol_hdl':           data.get('cholesterol_hdl'),
                'triglycerides':             data.get('triglycerides'),
                'blood_pressure_systolic':   data.get('blood_pressure_systolic'),
                'blood_pressure_diastolic':  data.get('blood_pressure_diastolic'),
                'vitamin_d':                 data.get('vitamin_d'),
                'vitamin_b12':               data.get('vitamin_b12'),
                'ferritin':                  data.get('ferritin'),
                'summary':                   data.get('summary', ''),
                'key_findings':              data.get('key_findings', []),
                'dietary_recommendations':   data.get('dietary_recommendations', []),
            }
        )
    except Exception:
        pass  # Analysis failure never blocks the upload


class MedicalDocumentUploadView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = MedicalDocumentSerializer(data=request.data)
        if serializer.is_valid():
            document = serializer.save(user=request.user)
            # Trigger AI analysis in background thread so upload returns immediately
            import threading
            threading.Thread(target=_analyze_document, args=(document,), daemon=True).start()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MedicalDocumentDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = MedicalDocumentSerializer
    http_method_names = ['get', 'patch', 'delete']

    def get_queryset(self):
        return MedicalDocument.objects.filter(user=self.request.user)


# NL-23 to NL-26 — Product analysis engine
class ProductAnalysisView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    _PROBLEMATIC = [
        'palm oil', 'huile de palme',
        'glucose-fructose', 'high fructose corn syrup', 'sirop de glucose',
        'partially hydrogenated', 'hydrogénée', 'partiellement hydrogéné',
        'aspartame', 'acesulfame', 'tartrazine', 'sodium nitrite',
    ]
    _E_PATTERN = re.compile(r'\bE[1-9]\d{2,3}\b', re.IGNORECASE)

    def post(self, request):
        profile = request.user.profile
        data = request.data
        nutrition = data.get('nutrition', {})
        allergens = [a.lower() for a in data.get('allergens', [])]
        ingredients_text = ' '.join(data.get('ingredients', [])).lower()
        nutriscore = (data.get('nutriscore') or '').lower()

        warnings = []
        highlighted = []
        recommendations = []

        # Latest lab results — used to sharpen thresholds (Layer 2 enrichment)
        lab = DocumentAnalysis.objects.filter(
            document__user=request.user
        ).order_by('-analyzed_at').first()

        # ── NL-23: Nutritional comparison vs health profile ──────────────────
        sugar = nutrition.get('sugar')
        salt = nutrition.get('salt')
        sat_fat = nutrition.get('saturated_fat')
        calories = nutrition.get('calories')
        # Unit hint from client — ml products use same values as approx (MVP)
        product_unit = data.get('unit', 'g').lower()  # 'g' or 'ml'

        # Medically-adjusted daily limits (OMS + clinical best practices).
        # Collect all applicable limits and take the strictest (min).
        sugar_candidates = [float(profile.sugar_limit_target or 50)]
        if profile.is_diabetic:
            sugar_candidates.append(25.0)
        if profile.goal in ('lose_weight', 'eat_healthy'):
            sugar_candidates.append(35.0)
        # Lab-driven tightening: prediabetic range (HbA1c 5.7-6.4) or borderline glucose
        if lab:
            if lab.hba1c is not None and lab.hba1c >= 5.7:
                sugar_candidates.append(30.0)
            if lab.blood_glucose is not None and lab.blood_glucose > 6.0:
                sugar_candidates.append(30.0)
        sugar_limit = min(sugar_candidates)

        salt_candidates = [float(profile.salt_limit_target or 5)]
        if profile.has_hypertension:
            salt_candidates.append(3.0)
        if profile.goal in ('lose_weight', 'eat_healthy'):
            salt_candidates.append(4.0)
        # Lab-driven tightening: elevated BP from blood test
        if lab and lab.blood_pressure_systolic is not None and lab.blood_pressure_systolic >= 120:
            salt_candidates.append(3.5)
        salt_limit = min(salt_candidates)

        # Data quality guard
        available_fields = sum(1 for v in [sugar, salt, sat_fat, calories] if v is not None)
        data_quality_low = available_fields < 2

        # intensities: {warning_code: float} — cap à 2.0
        intensities = {}

        # ── Helper: safe ratio clamp ─────────────────────────────────────────
        def _ratio(value, threshold):
            return max(0.0, min(2.0, float(value) / threshold))

        if sugar is not None:
            sugar_threshold = sugar_limit * 0.30
            ratio = _ratio(sugar, sugar_threshold)
            over_pct = int((ratio - 1) * 100)
            if ratio >= 1.0:
                sev = 'danger' if profile.is_diabetic else 'warning'
                intensities['high_sugar'] = ratio
                if profile.is_diabetic:
                    dtype = profile.diabetes_type
                    if dtype == 'type_1':
                        detail = f'Exceeds sugar limit by +{over_pct}% — requires insulin adjustment'
                        rec = 'Avoid — Type 1 diabetics must carefully match sugar intake to insulin.'
                    elif dtype == 'gestational':
                        detail = f'Exceeds sugar limit by +{over_pct}% — avoid during pregnancy'
                        rec = 'Avoid — gestational diabetes requires strict sugar control.'
                    else:
                        detail = f'Exceeds sugar limit by +{over_pct}% — avoid'
                        rec = 'Avoid — high sugar worsens insulin resistance in Type 2 diabetes.'
                else:
                    detail = f'Exceeds sugar threshold by +{over_pct}% — limit'
                    rec = 'Consider a lower-sugar alternative.'
                warnings.append({'code': 'high_sugar', 'label': 'High Sugar',
                                  'severity': sev, 'detail': detail})
                recommendations.append(rec)
            elif ratio >= 0.7:
                warnings.append({'code': 'soft_sugar',
                                  'label': 'Approaching sugar limit',
                                  'severity': 'info',
                                  'detail': f'Close to your sugar limit ({int(ratio * 100)}% of threshold) — monitor'})
        else:
            warnings.append({'code': 'missing_sugar', 'label': 'Sugar data not available',
                              'severity': 'info',
                              'detail': 'Sugar content missing — monitor'})

        if salt is not None:
            salt_threshold = salt_limit * 0.25
            ratio = _ratio(salt, salt_threshold)
            over_pct = int((ratio - 1) * 100)
            if ratio >= 1.0:
                sev = 'danger' if profile.has_hypertension else 'warning'
                intensities['high_salt'] = ratio
                detail = (
                    f'Exceeds your salt limit by +{over_pct}% — avoid'
                    if profile.has_hypertension
                    else f'Exceeds salt threshold by +{over_pct}% — limit'
                )
                warnings.append({'code': 'high_salt', 'label': 'High Salt',
                                  'severity': sev, 'detail': detail})
                recommendations.append(
                    'Limit consumption — high salt raises blood pressure.' if profile.has_hypertension
                    else 'Limit to 1 serving per day due to salt content.')
            elif ratio >= 0.7:
                warnings.append({'code': 'soft_salt',
                                  'label': 'Approaching salt limit',
                                  'severity': 'info',
                                  'detail': f'Close to your salt limit ({int(ratio * 100)}% of threshold) — monitor'})
        else:
            warnings.append({'code': 'missing_salt', 'label': 'Salt data not available',
                              'severity': 'info',
                              'detail': 'Salt content missing — monitor'})

        if sat_fat is not None:
            sat_fat_f = float(sat_fat)
            at_cardio_risk = profile.has_hypertension or profile.goal in ('lose_weight', 'eat_healthy')
            if sat_fat_f > 8:
                intensities['high_sat_fat'] = _ratio(sat_fat_f, 8.0)
                sev = 'danger' if profile.has_hypertension else 'warning'
                detail = (
                    f'Very high saturated fat ({sat_fat_f:.1f}g/100{product_unit}) — avoid'
                    if at_cardio_risk
                    else f'Very high saturated fat ({sat_fat_f:.1f}g/100{product_unit}) — limit'
                )
                warnings.append({'code': 'high_sat_fat', 'label': 'High Saturated Fat',
                                  'severity': sev, 'detail': detail})
                recommendations.append(
                    'Avoid — very high saturated fat, risky for your profile.' if at_cardio_risk
                    else 'Very high saturated fat — limit consumption.')
            elif sat_fat_f > 5:
                intensities['high_sat_fat'] = _ratio(sat_fat_f, 5.0)
                warnings.append({'code': 'high_sat_fat', 'label': 'High Saturated Fat',
                                  'severity': 'warning',
                                  'detail': f'High saturated fat ({sat_fat_f:.1f}g/100{product_unit}) — limit'})
                recommendations.append('Prefer unsaturated fat alternatives.')

        # ── Lab-driven cholesterol / sat-fat enrichment ──────────────────────
        if lab and sat_fat is not None:
            sat_fat_f = float(sat_fat)
            high_chol = (
                (lab.cholesterol_total is not None and lab.cholesterol_total > 5.2) or
                (lab.cholesterol_ldl is not None and lab.cholesterol_ldl > 3.4) or
                (lab.triglycerides is not None and lab.triglycerides > 1.7)
            )
            if high_chol and sat_fat_f > 3 and 'high_sat_fat' not in {w['code'] for w in warnings}:
                warnings.append({
                    'code': 'lab_sat_fat',
                    'label': 'Elevated cholesterol risk',
                    'severity': 'warning',
                    'detail': f'Your lab results show elevated lipids — limit saturated fat ({sat_fat_f:.1f}g/100{product_unit})',
                })
                recommendations.append('Limit saturated fat — your blood test shows elevated lipid levels.')

        # ── Allergens vs health conditions ───────────────────────────────────
        condition_map = {
            'gluten': profile.is_celiac, 'wheat': profile.is_celiac,
            'milk': profile.is_lactose_intolerant and profile.lactose_intolerance_level == 'severe',
            'lactose': profile.is_lactose_intolerant,
            'dairy': profile.is_lactose_intolerant and profile.lactose_intolerance_level == 'severe',
        }
        added_allergen_codes = set()
        has_critical_danger = False
        for allergen in allergens:
            for key, has_condition in condition_map.items():
                code = f'allergen_{key}'
                if key in allergen and has_condition and code not in added_allergen_codes:
                    added_allergen_codes.add(code)
                    has_critical_danger = True
                    warnings.append({'code': code,
                                     'label': f'Contains {allergen.title()}',
                                     'severity': 'danger',
                                     'detail': f'Contains {allergen} — not suitable for your condition'})
                    recommendations.append(
                        f'Avoid — contains {allergen} and you have a declared condition.')

        if profile.allergies:
            user_allergies = [a.strip().lower() for a in profile.allergies.split(',') if a.strip()]
            for ua in user_allergies:
                if any(ua in a for a in allergens):
                    has_critical_danger = True
                    warnings.append({'code': f'personal_allergen_{ua}',
                                     'label': f'Personal Allergen: {ua.title()}',
                                     'severity': 'danger',
                                     'detail': f'Contains {ua} — declared in your profile, avoid'})
                    recommendations.append(f'Avoid — contains {ua} (personal allergen).')

        # ── Vegan / Vegetarian ───────────────────────────────────────────────
        non_vegan_markers = ['milk', 'egg', 'meat', 'fish', 'gelatin', 'honey', 'cheese', 'beef', 'pork', 'chicken']
        non_veg_markers = ['meat', 'fish', 'beef', 'pork', 'chicken', 'gelatin']
        if profile.is_vegan:
            for m in non_vegan_markers:
                if m in ingredients_text:
                    warnings.append({'code': 'not_vegan', 'label': 'Not Vegan',
                                     'severity': 'warning', 'detail': f'Contains {m}'})
                    recommendations.append('Not suitable for vegans.')
                    break
        elif profile.is_vegetarian:
            for m in non_veg_markers:
                if m in ingredients_text:
                    warnings.append({'code': 'not_vegetarian', 'label': 'Not Vegetarian',
                                     'severity': 'warning', 'detail': f'Contains {m}'})
                    recommendations.append('Not suitable for vegetarians.')
                    break
        elif profile.is_flexitarian:
            heavy_meat = ['beef', 'pork', 'processed meat', 'sausage', 'bacon']
            for m in heavy_meat:
                if m in ingredients_text:
                    warnings.append({'code': 'high_meat', 'label': 'High meat content',
                                     'severity': 'info', 'detail': f'Contains {m} — consider limiting'})
                    recommendations.append('High meat content — flexitarian diet recommends limiting.')
                    break

        # ── NL-24: Problematic ingredients ───────────────────────────────────
        for ing in self._PROBLEMATIC:
            if ing in ingredients_text:
                highlighted.append(ing)
        e_matches = self._E_PATTERN.findall(ingredients_text)
        highlighted = list(set(highlighted + e_matches))

        if highlighted:
            warnings.append({'code': 'problematic_ingredients',
                              'label': 'Problematic Ingredients',
                              'severity': 'warning',
                              'detail': ', '.join(highlighted[:3]) +
                                        ('...' if len(highlighted) > 3 else '')})

        # ── Deduplicate ───────────────────────────────────────────────────────
        seen, deduped = set(), []
        for w in warnings:
            if w['code'] not in seen:
                seen.add(w['code'])
                deduped.append(w)

        # ── Score intelligent (NutriLens v3) ──────────────────────────────────
        # 1. Poids personnalisé selon le profil
        personal_weight = 1.0
        if profile.is_diabetic:
            personal_weight = max(personal_weight, 1.5)
        if profile.has_hypertension:
            personal_weight = max(personal_weight, 1.3)
        if profile.is_celiac or profile.is_lactose_intolerant:
            personal_weight = max(personal_weight, 1.4)
        if profile.goal in ('lose_weight', 'eat_healthy'):
            personal_weight = max(personal_weight, 1.1)

        # 2. Malus dégressif × poids × intensité
        danger_warnings = [w for w in deduped if w['severity'] == 'danger']
        warning_warnings = [w for w in deduped if w['severity'] == 'warning']
        nb_dangers = len(danger_warnings)
        nb_warnings = len(warning_warnings)

        danger_sum = 0.0
        for i, dw in enumerate(danger_warnings):
            base = 40.0 if i == 0 else 25.0
            intensity = intensities.get(dw['code'], 1.0)
            danger_sum += base * personal_weight * intensity

        # 3. Effet exponentiel sur les dangers multiples (cap ×1.6)
        exponential = 1 + min(0.2 * (nb_dangers - 1), 0.6) if nb_dangers > 0 else 1.0
        danger_malus = danger_sum * exponential

        # 4. Malus warnings avec léger scaling
        warning_base = nb_warnings * 10.0
        warning_scaling = 1 + 0.05 * (nb_warnings - 1) if nb_warnings > 0 else 1.0
        warning_malus = warning_base * warning_scaling

        # 5. Nutriscore penalty
        nutriscore_penalty = {'a': 0, 'b': -3, 'c': -7, 'd': -15, 'e': -25}
        ns_penalty = nutriscore_penalty.get(nutriscore, 0)

        # 6. Score final
        raw_score = 100 - danger_malus - warning_malus + ns_penalty

        if has_critical_danger:
            score = max(0, min(100, int(raw_score)))
        else:
            score = max(5, min(100, int(raw_score)))

        # 7. Data quality guard (applied first so other caps can further restrict)
        if data_quality_low:
            score = min(score, 80)
            deduped.insert(0, {
                'code': 'insufficient_data',
                'label': 'Incomplete nutritional data',
                'severity': 'info',
                'detail': 'Score may not reflect the full product profile',
            })

        # 8. Nutri-score D/E guard — poor nutritional quality even with no warnings
        if nutriscore in ('d', 'e'):
            score = min(score, 89)

        # 9. Caps différenciés warning vs soft warning
        has_warning = any(w['severity'] == 'warning' for w in deduped)
        has_soft_warning = any(w['severity'] == 'info' for w in deduped)
        if has_warning:
            score = min(score, 95)
        elif has_soft_warning:
            score = min(score, 97)

        # 10. Reasons — top 3, sorted by priority (critical allergen > danger > warning > info)
        def _priority(w):
            code = w['code']
            if code.startswith('allergen_') or code.startswith('personal_allergen_'):
                return 0  # critical allergen — always first
            if w['severity'] == 'danger':
                return 1
            if w['severity'] == 'warning':
                return 2
            return 3  # info

        candidate_reasons = []
        for w in sorted(deduped, key=_priority):
            if w['severity'] in ('danger', 'warning'):
                candidate_reasons.append(w['detail'])

        # Nutriscore reason (lower priority than nutrient warnings)
        if nutriscore and nutriscore != 'a':
            ns_labels = {'b': 'Nutri-score B — slightly reduces score',
                         'c': 'Nutri-score C (average) — reduces score',
                         'd': 'Nutri-score D (poor) — score capped at 89',
                         'e': 'Nutri-score E (very poor) — score capped at 89'}
            candidate_reasons.append(ns_labels.get(nutriscore, f'Nutri-score {nutriscore.upper()} reduces score'))

        if data_quality_low:
            candidate_reasons.append('Limited nutritional data — score capped at 80')

        if candidate_reasons:
            reasons = candidate_reasons[:3]
        else:
            # Score ≥ 85 with no issues — reinforce positively
            positives = []
            if sugar is not None and _ratio(sugar, sugar_limit * 0.30) < 0.7:
                positives.append('Low sugar — within your daily limit')
            if salt is not None and _ratio(salt, salt_limit * 0.25) < 0.7:
                positives.append('Low salt — suitable for your profile')
            if sat_fat is not None and float(sat_fat) <= 5:
                positives.append('Moderate saturated fat — acceptable level')
            if nutriscore in ('a', 'b'):
                positives.append(f'Nutri-score {nutriscore.upper()} — good nutritional quality')
            reasons = positives[:3] if positives else ['Within your daily limits for your profile']

        return Response({
            'warnings': deduped,
            'highlighted_ingredients': highlighted,
            'recommendations': list(dict.fromkeys(recommendations)),
            'score': score,
            'reasons': reasons,
            'lab_enriched': lab is not None,
        })


def _parse_date(date_str):
    """Parse YYYY-MM-DD string to date, raises ValueError on invalid format."""
    from datetime import datetime
    return datetime.strptime(date_str, '%Y-%m-%d').date()


def _parse_week(week_str):
    """Parse 'YYYY-Www' (e.g. 2026-W15) → (week_start, week_end) as date objects."""
    from datetime import datetime, timedelta
    dt = datetime.strptime(week_str + '-1', '%G-W%V-%u').date()
    return dt, dt + timedelta(days=6)


class FoodIntakeListView(APIView):
    """POST: log a food intake. GET: list for a given date (default: today UTC)."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        date_str = request.query_params.get('date')
        try:
            day = _parse_date(date_str) if date_str else timezone.now().date()
        except ValueError:
            return Response({'error': 'Invalid date format. Use YYYY-MM-DD.'}, status=400)
        qs = FoodIntake.objects.filter(user=request.user, date=day)
        serializer = FoodIntakeSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = FoodIntakeSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class FoodIntakeDetailView(APIView):
    """PATCH / DELETE a food intake entry."""
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, pk):
        try:
            intake = FoodIntake.objects.get(pk=pk, user=request.user)
        except FoodIntake.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
        serializer = FoodIntakeSerializer(intake, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        try:
            intake = FoodIntake.objects.get(pk=pk, user=request.user)
        except FoodIntake.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
        intake.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class FoodIntakeMonthlyView(APIView):
    """GET monthly report — NL-50. ?month=2026-04 (default: current month)."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from datetime import timedelta, date as date_type
        import calendar

        month_str = request.query_params.get('month')
        try:
            if month_str:
                from datetime import datetime
                parsed = datetime.strptime(month_str, '%Y-%m')
                year, month = parsed.year, parsed.month
            else:
                today = timezone.now().date()
                year, month = today.year, today.month
        except ValueError:
            return Response(
                {'error': 'Invalid month format. Use YYYY-MM (e.g. 2026-04).'},
                status=400,
            )

        month_start = date_type(year, month, 1)
        last_day = calendar.monthrange(year, month)[1]
        month_end = date_type(year, month, last_day)

        profile = getattr(request.user, 'profile', None)
        calorie_target = profile.daily_calorie_target if profile else None
        protein_target = profile.protein_target if profile else None
        carbs_target = profile.carbs_target if profile else None
        fat_target = profile.fat_target if profile else None

        intakes = FoodIntake.objects.filter(
            user=request.user,
            date__range=[month_start, month_end],
        )

        from collections import defaultdict
        by_date = defaultdict(list)
        for i in intakes:
            by_date[i.date].append(i)

        def _day_status(total_cal, cal_target, has_data):
            if not has_data:
                return 'no_data'
            if cal_target and cal_target > 0:
                pct = total_cal / cal_target * 100
                if pct > 110:
                    return 'exceeded'
                if total_cal > 0 and cal_target - total_cal <= 200:
                    return 'warning'
            return 'on_track'

        # Build ISO weeks covering the month
        # Find the Monday of the week containing month_start
        first_monday = month_start - timedelta(days=month_start.weekday())

        weeks = []
        cursor = first_monday
        while cursor <= month_end:
            week_start = cursor
            week_end_w = cursor + timedelta(days=6)
            # Clamp to month boundaries for display
            display_start = max(week_start, month_start)
            display_end = min(week_end_w, month_end)

            week_intakes = []
            for offset in range(7):
                d = week_start + timedelta(days=offset)
                week_intakes.extend(by_date.get(d, []))

            days_with_data = [
                week_start + timedelta(days=o)
                for o in range(7)
                if by_date.get(week_start + timedelta(days=o))
            ]
            has_data = len(days_with_data) > 0

            total_cal = round(sum(i.calories for i in week_intakes), 1)
            total_protein = round(sum(i.protein or 0 for i in week_intakes), 1)
            total_carbs = round(sum(i.carbs or 0 for i in week_intakes), 1)
            total_fat = round(sum(i.fat or 0 for i in week_intakes), 1)

            days_in_week = min(7, (display_end - display_start).days + 1)
            avg_cal = round(total_cal / days_in_week, 1) if days_in_week > 0 else 0.0
            week_target = round(calorie_target * days_in_week, 1) if calorie_target else None
            adherence = round(total_cal / week_target * 100, 1) if (week_target and week_target > 0) else None

            # week status based on avg vs daily target
            status = _day_status(avg_cal, calorie_target, has_data)

            # Human-readable label: "Apr 1–7" (strictly within the month)
            _month_abbr = ['Jan','Feb','Mar','Apr','May','Jun',
                           'Jul','Aug','Sep','Oct','Nov','Dec']
            week_label = (
                f'{_month_abbr[display_start.month - 1]} {display_start.day}'
                f'–{display_end.day}'
            )

            weeks.append({
                'week': week_label,
                'week_start': str(display_start),
                'week_end': str(display_end),
                'has_data': has_data,
                'total_calories': total_cal,
                'total_protein': total_protein,
                'total_carbs': total_carbs,
                'total_fat': total_fat,
                'avg_calories_per_day': avg_cal,
                'calorie_target_week': week_target,
                'calorie_target_daily': calorie_target,
                'adherence_pct': adherence,
                'status': status,
                'days_logged': len(days_with_data),
                'days_in_week': days_in_week,
            })
            cursor += timedelta(days=7)

        # Monthly aggregates
        all_day_cals = []
        for d_date, d_intakes in by_date.items():
            if month_start <= d_date <= month_end:
                all_day_cals.append(sum(i.calories for i in d_intakes))

        avg_calories = round(sum(all_day_cals) / len(all_day_cals), 1) if all_day_cals else 0.0
        total_calories_month = round(sum(all_day_cals), 1)
        days_logged = len(all_day_cals)
        days_on_track = sum(
            1 for d_date, d_intakes in by_date.items()
            if month_start <= d_date <= month_end and
            _day_status(sum(i.calories for i in d_intakes), calorie_target, True) == 'on_track'
        )
        days_exceeded = sum(
            1 for d_date, d_intakes in by_date.items()
            if month_start <= d_date <= month_end and
            _day_status(sum(i.calories for i in d_intakes), calorie_target, True) == 'exceeded'
        )

        # best/worst day (distance to target)
        best_day = worst_day = None
        if all_day_cals and calorie_target:
            day_cal_list = [
                (str(d_date), sum(i.calories for i in d_intakes))
                for d_date, d_intakes in by_date.items()
                if month_start <= d_date <= month_end
            ]
            sorted_dist = sorted(day_cal_list, key=lambda x: abs(x[1] - calorie_target))
            best_day = sorted_dist[0][0]
            worst_day = sorted_dist[-1][0]

        # Trend vs previous month
        prev_month = month - 1 if month > 1 else 12
        prev_year = year if month > 1 else year - 1
        prev_last_day = calendar.monthrange(prev_year, prev_month)[1]
        prev_start = date_type(prev_year, prev_month, 1)
        prev_end = date_type(prev_year, prev_month, prev_last_day)

        prev_intakes = FoodIntake.objects.filter(
            user=request.user, date__range=[prev_start, prev_end]
        )
        prev_by_date = defaultdict(list)
        for i in prev_intakes:
            prev_by_date[i.date].append(i)
        prev_day_cals = [sum(i.calories for i in v) for v in prev_by_date.values() if v]
        prev_avg = round(sum(prev_day_cals) / len(prev_day_cals), 1) if prev_day_cals else None

        if prev_avg and avg_calories:
            diff = avg_calories - prev_avg
            trend = 'stable' if abs(diff) < 50 else ('up' if diff > 0 else 'down')
        else:
            trend = 'stable'

        trend_labels = {
            'up': 'More calories than last month',
            'down': 'Fewer calories than last month',
            'stable': 'Similar intake to last month',
        }

        import calendar as cal_module
        month_name = cal_module.month_name[month]

        return Response({
            'month': month_str or f'{year}-{str(month).zfill(2)}',
            'month_name': f'{month_name} {year}',
            'month_start': str(month_start),
            'month_end': str(month_end),
            'weeks': weeks,
            'summary': {
                'avg_calories': avg_calories,
                'total_calories': total_calories_month,
                'calorie_target': calorie_target,
                'protein_target': protein_target,
                'carbs_target': carbs_target,
                'fat_target': fat_target,
                'days_logged': days_logged,
                'days_in_month': last_day,
                'days_on_track': days_on_track,
                'days_exceeded': days_exceeded,
                'best_day': best_day,
                'worst_day': worst_day,
                'trend': trend,
                'trend_label': trend_labels[trend],
            },
        })


class FoodIntakeWeeklyView(APIView):
    """GET weekly report — NL-49. ?week=2026-W15 (default: current ISO week)."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from datetime import timedelta
        week_str = request.query_params.get('week')
        try:
            if week_str:
                week_start, week_end = _parse_week(week_str)
            else:
                today = timezone.now().date()
                # ISO weekday: Mon=1 … Sun=7
                week_start = today - timedelta(days=today.weekday())
                week_end = week_start + timedelta(days=6)
        except ValueError:
            return Response(
                {'error': 'Invalid week format. Use YYYY-Www (e.g. 2026-W15).'},
                status=400,
            )

        profile = getattr(request.user, 'profile', None)
        calorie_target = profile.daily_calorie_target if profile else None
        protein_target = profile.protein_target if profile else None
        carbs_target = profile.carbs_target if profile else None
        fat_target = profile.fat_target if profile else None

        # Single query covering the whole week
        intakes = FoodIntake.objects.filter(
            user=request.user,
            date__range=[week_start, week_end],
        )

        # Group intakes by date
        from collections import defaultdict
        by_date = defaultdict(list)
        for i in intakes:
            by_date[i.date].append(i)

        def _day_status(total_cal, cal_target, has_data):
            if not has_data:
                return 'no_data'
            if cal_target and cal_target > 0:
                pct = total_cal / cal_target * 100
                if pct > 110:
                    return 'exceeded'
                if total_cal > 0 and cal_target - total_cal <= 200:
                    return 'warning'
            return 'on_track'

        days = []
        cal_totals_with_data = []

        for offset in range(7):
            day = week_start + timedelta(days=offset)
            day_intakes = by_date.get(day, [])
            has_data = len(day_intakes) > 0

            total_cal = round(sum(i.calories for i in day_intakes), 1)
            total_protein = round(sum(i.protein or 0 for i in day_intakes), 1)
            total_carbs = round(sum(i.carbs or 0 for i in day_intakes), 1)
            total_fat = round(sum(i.fat or 0 for i in day_intakes), 1)

            adherence = round(total_cal / calorie_target * 100, 1) if (calorie_target and calorie_target > 0) else None

            days.append({
                'date': str(day),
                'weekday': day.weekday(),  # 0=Mon … 6=Sun
                'has_data': has_data,
                'total_calories': total_cal,
                'total_protein': total_protein,
                'total_carbs': total_carbs,
                'total_fat': total_fat,
                'calorie_target': calorie_target,
                'protein_target': protein_target,
                'carbs_target': carbs_target,
                'fat_target': fat_target,
                'adherence_pct': adherence,
                'status': _day_status(total_cal, calorie_target, has_data),
                'entry_count': len(day_intakes),
            })

            if has_data:
                cal_totals_with_data.append((str(day), total_cal))

        # ── Weekly aggregates ────────────────────────────────────────────────
        days_with_data = [d for d in days if d['has_data']]
        days_on_track = sum(1 for d in days if d['status'] == 'on_track')
        days_warning = sum(1 for d in days if d['status'] == 'warning')
        days_exceeded = sum(1 for d in days if d['status'] == 'exceeded')
        days_no_data = sum(1 for d in days if d['status'] == 'no_data')

        avg_calories = round(
            sum(d['total_calories'] for d in days_with_data) / len(days_with_data), 1
        ) if days_with_data else 0.0
        avg_protein = round(
            sum(d['total_protein'] for d in days_with_data) / len(days_with_data), 1
        ) if days_with_data else 0.0

        # best/worst = closest/furthest from target (distance logic)
        best_day = worst_day = None
        if days_with_data and calorie_target:
            sorted_by_distance = sorted(
                days_with_data,
                key=lambda d: abs(d['total_calories'] - calorie_target),
            )
            best_day = sorted_by_distance[0]['date']
            worst_day = sorted_by_distance[-1]['date']
        elif days_with_data:
            best_day = max(days_with_data, key=lambda d: d['total_calories'])['date']
            worst_day = min(days_with_data, key=lambda d: d['total_calories'])['date']

        # ── Trend vs previous week ───────────────────────────────────────────
        prev_start = week_start - timedelta(days=7)
        prev_end = week_start - timedelta(days=1)
        prev_intakes = FoodIntake.objects.filter(
            user=request.user,
            date__range=[prev_start, prev_end],
        )
        prev_by_date = defaultdict(list)
        for i in prev_intakes:
            prev_by_date[i.date].append(i)

        prev_days_with_data = [
            d for offset in range(7)
            for d in [prev_start + timedelta(days=offset)]
            if prev_by_date.get(d)
        ]
        if prev_days_with_data:
            prev_avg = sum(
                sum(i.calories for i in prev_by_date[d])
                for d in prev_days_with_data
            ) / len(prev_days_with_data)
        else:
            prev_avg = None

        if prev_avg and avg_calories:
            diff = avg_calories - prev_avg
            if abs(diff) < 50:
                trend = 'stable'
            elif diff > 0:
                trend = 'up'
            else:
                trend = 'down'
        else:
            trend = 'stable'

        # Trend label for display
        trend_labels = {
            'up': 'More calories than last week',
            'down': 'Fewer calories than last week',
            'stable': 'Similar intake to last week',
        }

        return Response({
            'week': week_str or week_start.strftime('%G-W%V'),
            'week_start': str(week_start),
            'week_end': str(week_end),
            'days': days,
            'summary': {
                'avg_calories': avg_calories,
                'avg_protein': avg_protein,
                'calorie_target': calorie_target,
                'best_day': best_day,
                'worst_day': worst_day,
                'days_on_track': days_on_track,
                'days_warning': days_warning,
                'days_exceeded': days_exceeded,
                'days_no_data': days_no_data,
                'trend': trend,
                'trend_label': trend_labels[trend],
            },
        })


class FoodIntakeSummaryView(APIView):
    """GET daily totals — calories + macros + adherence per macro."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        date_str = request.query_params.get('date')
        try:
            day = _parse_date(date_str) if date_str else timezone.now().date()
        except ValueError:
            return Response({'error': 'Invalid date format. Use YYYY-MM-DD.'}, status=400)

        intakes = FoodIntake.objects.filter(user=request.user, date=day)

        def _sum(field):
            vals = [getattr(i, field) for i in intakes if getattr(i, field) is not None]
            return round(sum(vals), 1) if vals else 0.0

        def _adherence(total, target):
            if target and target > 0:
                return round(total / target * 100, 1)
            return None

        profile = getattr(request.user, 'profile', None)
        calorie_target = profile.daily_calorie_target if profile else None
        protein_target = profile.protein_target if profile else None
        carbs_target = profile.carbs_target if profile else None
        fat_target = profile.fat_target if profile else None

        total_calories = _sum('calories')
        total_protein = _sum('protein')
        total_carbs = _sum('carbs')
        total_fat = _sum('fat')

        remaining_calories = round(calorie_target - total_calories, 1) if calorie_target else None

        adherence_calories = _adherence(total_calories, calorie_target)
        adherence_protein = _adherence(total_protein, protein_target)
        adherence_carbs = _adherence(total_carbs, carbs_target)
        adherence_fat = _adherence(total_fat, fat_target)

        macro_adherences = [adherence_protein, adherence_carbs, adherence_fat]

        def _status():
            if adherence_calories and adherence_calories > 110:
                return 'exceeded'
            if any(a and a > 110 for a in macro_adherences):
                return 'exceeded'
            if remaining_calories is not None and 0 < remaining_calories <= 200:
                return 'warning'
            if any(a and a > 90 for a in macro_adherences):
                return 'warning'
            return 'on_track'

        return Response({
            'date': str(day),
            # Totals
            'total_calories': total_calories,
            'total_protein': total_protein,
            'total_carbs': total_carbs,
            'total_fat': total_fat,
            'total_sugar': _sum('sugar'),
            'total_salt': _sum('salt'),
            # Targets
            'calorie_target': calorie_target,
            'protein_target': protein_target,
            'carbs_target': carbs_target,
            'fat_target': fat_target,
            # Adherence per macro
            'adherence_pct': adherence_calories,
            'protein_adherence_pct': adherence_protein,
            'carbs_adherence_pct': adherence_carbs,
            'fat_adherence_pct': adherence_fat,
            # UX helpers
            'remaining_calories': remaining_calories,
            'status': _status(),
            'entry_count': intakes.count(),
        })


class BehavioralInsightsView(APIView):
    """NL-57 — Behavioral insights from last 28 days of food intake."""
    permission_classes = [permissions.IsAuthenticated]

    _WEEKDAY_NAMES = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
                      'Friday', 'Saturday', 'Sunday']

    def get(self, request):
        from datetime import timedelta
        from collections import defaultdict

        today = timezone.now().date()
        start = today - timedelta(days=27)

        intakes = FoodIntake.objects.filter(
            user=request.user,
            date__range=[start, today],
        )

        by_date = defaultdict(list)
        for i in intakes:
            by_date[i.date].append(i)

        total_days = 28
        days_logged = len(by_date)
        consistency_pct = round(days_logged / total_days * 100)

        # Current streak — tolère que aujourd'hui soit vide (avant premier log de la journée)
        streak = 0
        d = today if by_date.get(today) else today - timedelta(days=1)
        while d >= start:
            if by_date.get(d):
                streak += 1
            else:
                break
            d -= timedelta(days=1)

        # Avg calories by weekday
        wd_calories = defaultdict(list)
        for date, items in by_date.items():
            wd_calories[date.weekday()].append(sum(i.calories for i in items))

        avg_by_wd = {
            wd: round(sum(vals) / len(vals), 1)
            for wd, vals in wd_calories.items()
        }

        profile = getattr(request.user, 'profile', None)
        calorie_target = (profile.daily_calorie_target if profile else None) or 2000

        active_wds = {k: v for k, v in avg_by_wd.items() if v > 0}
        busiest_wd = max(active_wds, key=lambda k: active_wds[k]) if active_wds else 0
        best_wd = min(active_wds, key=lambda k: abs(active_wds[k] - calorie_target)) if active_wds else 0
        worst_wd = max(active_wds, key=lambda k: abs(active_wds[k] - calorie_target)) if active_wds else 0

        # Top foods (by frequency)
        food_counts = defaultdict(int)
        for items in by_date.values():
            for item in items:
                if item.name:
                    food_counts[item.name] += 1
        top_foods = sorted(food_counts.items(), key=lambda x: -x[1])[:5]

        # Meal type distribution
        meal_dist = defaultdict(int)
        for items in by_date.values():
            for item in items:
                meal_dist[item.meal_type] += 1

        # Avg daily calories (last 7 vs previous 7 days)
        last7_start = today - timedelta(days=6)
        prev7_start = today - timedelta(days=13)
        prev7_end = today - timedelta(days=7)

        def _avg_cal(date_from, date_to):
            days = [d for d in by_date if date_from <= d <= date_to]
            if not days:
                return 0.0
            return round(sum(
                sum(i.calories for i in by_date[d]) for d in days
            ) / len(days), 1)

        avg_last7 = _avg_cal(last7_start, today)
        avg_prev7 = _avg_cal(prev7_start, prev7_end)
        trend = 'up' if avg_last7 > avg_prev7 + 50 else \
                'down' if avg_last7 < avg_prev7 - 50 else 'stable'

        return Response({
            'period_days': total_days,
            'days_logged': days_logged,
            'consistency_pct': consistency_pct,
            'current_streak': streak,
            'calorie_target': calorie_target,
            'avg_by_weekday': [
                {'day': self._WEEKDAY_NAMES[i], 'calories': avg_by_wd.get(i, 0.0)}
                for i in range(7)
            ],
            'busiest_day': self._WEEKDAY_NAMES[busiest_wd],
            'best_day': self._WEEKDAY_NAMES[best_wd],
            'worst_day': self._WEEKDAY_NAMES[worst_wd],
            'top_foods': [{'name': n, 'count': c} for n, c in top_foods],
            'meal_distribution': dict(meal_dist),
            'avg_calories_last7': avg_last7,
            'avg_calories_prev7': avg_prev7,
            'week_trend': trend,
        })


class MedicalConsentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        profile = request.user.profile
        profile.medical_consent_accepted = True
        profile.medical_consent_at = timezone.now()
        profile.save(update_fields=['medical_consent_accepted', 'medical_consent_at'])
        return Response({'accepted': True, 'accepted_at': profile.medical_consent_at})


class NutriBotView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def _build_system_prompt(self, user):
        profile = getattr(user, 'profile', None)
        if not profile:
            return "You are NutriBot, a helpful nutrition assistant inside the NutriLens app."

        lines = [
            "You are NutriBot, an expert nutrition assistant inside the NutriLens app.",
            "Answer questions about food, nutrition, health, and diet. Be concise and practical.",
            "",
            "User profile:",
            f"- Goal: {profile.goal}",
            f"- Activity: {profile.activity_frequency} days/week, {profile.activity_intensity} intensity",
            f"- Lifestyle: {profile.lifestyle}",
        ]

        if profile.daily_calorie_target:
            lines.append(f"- Daily calorie target: {profile.daily_calorie_target} kcal")
        if profile.bmi:
            lines.append(f"- BMI: {profile.bmi}")

        conditions = []
        if profile.is_diabetic:
            conditions.append(f"diabetes ({profile.diabetes_type})" if profile.diabetes_type else "diabetes")
        if profile.has_hypertension:
            conditions.append("hypertension")
        if profile.is_celiac:
            conditions.append("celiac disease")
        if profile.is_lactose_intolerant:
            level = f" ({profile.lactose_intolerance_level})" if profile.lactose_intolerance_level else ""
            conditions.append(f"lactose intolerance{level}")
        if profile.is_vegan:
            conditions.append("vegan")
        if profile.is_vegetarian:
            conditions.append("vegetarian")
        if profile.is_flexitarian:
            conditions.append("flexitarian")
        if conditions:
            lines.append(f"- Health conditions/diet: {', '.join(conditions)}")
        if profile.allergies:
            lines.append(f"- Allergies: {profile.allergies}")

        # Inject latest lab results from medical documents
        latest = DocumentAnalysis.objects.filter(
            document__user=user
        ).order_by('-analyzed_at').first()
        if latest:
            lab_lines = []
            if latest.blood_glucose is not None:
                lab_lines.append(f"blood glucose {latest.blood_glucose} mmol/L")
            if latest.hba1c is not None:
                lab_lines.append(f"HbA1c {latest.hba1c}%")
            if latest.cholesterol_total is not None:
                lab_lines.append(f"total cholesterol {latest.cholesterol_total} mmol/L")
            if latest.cholesterol_ldl is not None:
                lab_lines.append(f"LDL {latest.cholesterol_ldl} mmol/L")
            if latest.cholesterol_hdl is not None:
                lab_lines.append(f"HDL {latest.cholesterol_hdl} mmol/L")
            if latest.triglycerides is not None:
                lab_lines.append(f"triglycerides {latest.triglycerides} mmol/L")
            if latest.blood_pressure_systolic is not None:
                lab_lines.append(f"BP {latest.blood_pressure_systolic}/{latest.blood_pressure_diastolic} mmHg")
            if latest.vitamin_d is not None:
                lab_lines.append(f"vitamin D {latest.vitamin_d} ng/mL")
            if latest.vitamin_b12 is not None:
                lab_lines.append(f"vitamin B12 {latest.vitamin_b12} pg/mL")
            if latest.ferritin is not None:
                lab_lines.append(f"ferritin {latest.ferritin} ng/mL")
            if lab_lines:
                lines.append("")
                lines.append("Latest lab results (from uploaded medical document):")
                for l in lab_lines:
                    lines.append(f"- {l}")
                if latest.key_findings:
                    lines.append(f"- Key findings: {'; '.join(latest.key_findings[:3])}")
                lines.append("Use these values to give more precise, personalised dietary advice.")

        lines += [
            "",
            "Always tailor advice to the user's profile. Keep responses short (2-4 sentences max) unless a detailed explanation is needed.",
        ]
        return "\n".join(lines)

    def post(self, request):
        api_key = settings.GROQ_API_KEY
        if not api_key:
            return Response({'error': 'NutriBot is not configured yet.'},
                            status=status.HTTP_503_SERVICE_UNAVAILABLE)

        message = request.data.get('message', '').strip()
        history = request.data.get('history', [])

        if not message:
            return Response({'error': 'message is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        try:
            from groq import Groq
            client = Groq(api_key=api_key)

            messages = [{'role': 'system', 'content': self._build_system_prompt(request.user)}]
            for h in history[-10:]:
                if h.get('role') in ('user', 'assistant') and h.get('content'):
                    messages.append({'role': h['role'], 'content': h['content']})
            messages.append({'role': 'user', 'content': message})

            completion = client.chat.completions.create(
                model='llama-3.1-8b-instant',
                messages=messages,
                max_tokens=512,
                temperature=0.7,
            )
            reply = completion.choices[0].message.content
            return Response({'reply': reply})

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
