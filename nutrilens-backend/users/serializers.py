from django.contrib.auth.models import User
from rest_framework import serializers
from .models import UserProfile, HealthSnapshot, MedicalDocument, FoodIntake, DocumentAnalysis


class UserProfileSerializer(serializers.ModelSerializer):
    bmi = serializers.ReadOnlyField()
    age = serializers.ReadOnlyField()
    is_profile_complete = serializers.ReadOnlyField()
    daily_calorie_target = serializers.ReadOnlyField()
    protein_target = serializers.ReadOnlyField()
    carbs_target = serializers.ReadOnlyField()
    fat_target = serializers.ReadOnlyField()
    sugar_limit_target = serializers.ReadOnlyField()
    salt_limit_target = serializers.ReadOnlyField()
    activity_score = serializers.ReadOnlyField()
    activity_multiplier = serializers.ReadOnlyField()

    class Meta:
        model = UserProfile
        fields = [
            'id', 'gender', 'date_of_birth', 'age',
            'weight', 'height', 'goal', 'activity_level',
            'activity_frequency', 'activity_intensity',
            'activity_duration', 'activity_types', 'lifestyle',
            'activity_score', 'activity_multiplier',
            'medical_consent_accepted', 'medical_consent_at',
            'is_diabetic', 'has_hypertension', 'is_celiac',
            'is_lactose_intolerant', 'is_vegan', 'is_vegetarian', 'is_flexitarian',
            'diabetes_type', 'lactose_intolerance_level',
            'allergies', 'avatar',
            'daily_calories', 'daily_protein', 'daily_carbs',
            'daily_fat', 'daily_sugar_limit', 'daily_salt_limit',
            'is_profile_complete', 'bmi', 'daily_calorie_target',
            'protein_target', 'carbs_target', 'fat_target',
            'sugar_limit_target', 'salt_limit_target',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'is_profile_complete', 'bmi', 'age',
            'activity_score', 'activity_multiplier',
            'daily_calorie_target', 'protein_target', 'carbs_target',
            'fat_target', 'sugar_limit_target', 'salt_limit_target',
            'medical_consent_at',
            'created_at', 'updated_at',
        ]


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    profile = UserProfileSerializer(required=False)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'profile']

    def create(self, validated_data):
        profile_data = validated_data.pop('profile', {})
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password']
        )
        UserProfile.objects.create(user=user, **profile_data)
        return user


class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'is_staff', 'profile']
        read_only_fields = ['is_staff']

    def update(self, instance, validated_data):
        profile_data = validated_data.pop('profile', {})

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        profile = instance.profile
        for attr, value in profile_data.items():
            setattr(profile, attr, value)
        profile.save()

        return instance


class HealthSnapshotSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthSnapshot
        fields = ['id', 'weight', 'bmi', 'daily_calorie_target',
                  'notes', 'source', 'recorded_at']
        read_only_fields = ['id', 'recorded_at']


class DocumentAnalysisSerializer(serializers.ModelSerializer):
    class Meta:
        model = DocumentAnalysis
        fields = [
            'id', 'blood_glucose', 'hba1c', 'cholesterol_total',
            'cholesterol_ldl', 'cholesterol_hdl', 'triglycerides',
            'blood_pressure_systolic', 'blood_pressure_diastolic',
            'vitamin_d', 'vitamin_b12', 'ferritin',
            'summary', 'key_findings', 'dietary_recommendations',
            'analyzed_at',
        ]
        read_only_fields = fields


class MedicalDocumentSerializer(serializers.ModelSerializer):
    analysis = DocumentAnalysisSerializer(read_only=True)

    class Meta:
        model = MedicalDocument
        fields = ['id', 'title', 'document_type', 'file',
                  'notes', 'uploaded_at', 'analysis']
        read_only_fields = ['id', 'uploaded_at', 'analysis']


class FoodIntakeSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodIntake
        fields = [
            'id', 'product', 'name', 'image_url', 'source_type',
            'quantity', 'unit', 'unit_label',
            'calories', 'protein', 'carbs', 'fat', 'sugar', 'salt',
            'meal_type', 'consumed_at', 'date', 'weekday',
            'confidence_score', 'created_at',
        ]
        read_only_fields = ['id', 'date', 'weekday', 'created_at']
