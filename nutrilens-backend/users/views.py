import re
from django.contrib.auth.models import User
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.utils import timezone
from .models import HealthSnapshot, MedicalDocument, FoodIntake
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
        return HealthSnapshot.objects.filter(user=self.request.user)

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


class MedicalDocumentUploadView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = MedicalDocumentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
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
        sugar_limit = min(sugar_candidates)

        salt_candidates = [float(profile.salt_limit_target or 5)]
        if profile.has_hypertension:
            salt_candidates.append(3.0)
        if profile.goal in ('lose_weight', 'eat_healthy'):
            salt_candidates.append(4.0)
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
                detail = (
                    f'Exceeds your sugar limit by +{over_pct}% — avoid'
                    if profile.is_diabetic
                    else f'Exceeds sugar threshold by +{over_pct}% — limit'
                )
                warnings.append({'code': 'high_sugar', 'label': 'High Sugar',
                                  'severity': sev, 'detail': detail})
                recommendations.append(
                    'Avoid — high sugar is dangerous for diabetics.' if profile.is_diabetic
                    else 'Consider a lower-sugar alternative.')
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

        # ── Allergens vs health conditions ───────────────────────────────────
        condition_map = {
            'gluten': profile.is_celiac, 'wheat': profile.is_celiac,
            'milk': profile.is_lactose_intolerant,
            'lactose': profile.is_lactose_intolerant,
            'dairy': profile.is_lactose_intolerant,
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
