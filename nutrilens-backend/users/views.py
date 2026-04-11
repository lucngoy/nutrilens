import re
from django.contrib.auth.models import User
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import HealthSnapshot, MedicalDocument
from .serializers import (
    RegisterSerializer, UserSerializer, UserProfileSerializer,
    HealthSnapshotSerializer, MedicalDocumentSerializer,
)


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

        warnings = []
        highlighted = []
        recommendations = []

        # ── NL-23: Nutritional comparison vs health profile ──────────────────
        sugar = nutrition.get('sugar')
        salt = nutrition.get('salt')
        sat_fat = nutrition.get('saturated_fat')
        sugar_limit = float(profile.sugar_limit_target or 50)
        salt_limit = float(profile.salt_limit_target or 6)

        if sugar is not None:
            if float(sugar) > sugar_limit * 0.30:
                sev = 'danger' if profile.is_diabetic else 'warning'
                detail = f'{float(sugar):.1f}g per 100g'
                if profile.is_diabetic:
                    detail += ' — critical for diabetics'
                warnings.append({'code': 'high_sugar', 'label': 'High Sugar',
                                  'severity': sev, 'detail': detail})
                recommendations.append(
                    'Avoid — high sugar is dangerous for diabetics.' if profile.is_diabetic
                    else 'Consider a lower-sugar alternative.')

        if salt is not None:
            if float(salt) > salt_limit * 0.25:
                sev = 'danger' if profile.has_hypertension else 'warning'
                detail = f'{float(salt):.2f}g per 100g'
                if profile.has_hypertension:
                    detail += ' — risky for hypertension'
                warnings.append({'code': 'high_salt', 'label': 'High Salt',
                                  'severity': sev, 'detail': detail})
                recommendations.append(
                    'Limit consumption — high salt raises blood pressure.' if profile.has_hypertension
                    else 'Limit to 1 serving per day due to salt content.')

        if sat_fat is not None and float(sat_fat) > 5:
            warnings.append({'code': 'high_sat_fat', 'label': 'High Saturated Fat',
                              'severity': 'warning',
                              'detail': f'{float(sat_fat):.1f}g per 100g'})
            recommendations.append('Prefer unsaturated fat alternatives.')

        # ── Allergens vs health conditions ───────────────────────────────────
        condition_map = {
            'gluten': profile.is_celiac, 'wheat': profile.is_celiac,
            'milk': profile.is_lactose_intolerant,
            'lactose': profile.is_lactose_intolerant,
            'dairy': profile.is_lactose_intolerant,
        }
        added_allergen_codes = set()
        for allergen in allergens:
            for key, has_condition in condition_map.items():
                code = f'allergen_{key}'
                if key in allergen and has_condition and code not in added_allergen_codes:
                    added_allergen_codes.add(code)
                    warnings.append({'code': code,
                                     'label': f'Contains {allergen.title()}',
                                     'severity': 'danger',
                                     'detail': 'Matches your health condition'})
                    recommendations.append(
                        f'Avoid — contains {allergen} and you have a declared condition.')

        if profile.allergies:
            user_allergies = [a.strip().lower() for a in profile.allergies.split(',') if a.strip()]
            for ua in user_allergies:
                if any(ua in a for a in allergens):
                    warnings.append({'code': f'personal_allergen_{ua}',
                                     'label': f'Personal Allergen: {ua.title()}',
                                     'severity': 'danger',
                                     'detail': 'Declared in your health profile'})
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

        # ── Score intelligent (NutriLens v2) ──────────────────────────────────
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

        # 2. Malus dégressif par danger (1er = −40, suivants = −25) × poids
        danger_warnings = [w for w in deduped if w['severity'] == 'danger']
        warning_warnings = [w for w in deduped if w['severity'] == 'warning']
        nb_dangers = len(danger_warnings)

        danger_sum = 0.0
        for i in range(nb_dangers):
            base = 40.0 if i == 0 else 25.0
            danger_sum += base * personal_weight

        # 3. Effet exponentiel sur les dangers multiples
        exponential = 1 + 0.2 * (nb_dangers - 1) if nb_dangers > 0 else 1.0
        danger_malus = danger_sum * exponential

        # 4. Malus warnings (flat)
        warning_malus = len(warning_warnings) * 10

        score = max(0, min(100, int(100 - danger_malus - warning_malus)))

        return Response({
            'warnings': deduped,
            'highlighted_ingredients': highlighted,
            'recommendations': list(dict.fromkeys(recommendations)),
            'score': score,
        })
