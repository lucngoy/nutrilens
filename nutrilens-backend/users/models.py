from django.db import models
from django.contrib.auth.models import User
from datetime import date


class UserProfile(models.Model):
    GOAL_CHOICES = [
        ('lose_weight', 'Lose Weight'),
        ('gain_muscle', 'Gain Muscle'),
        ('maintain', 'Maintain'),
        ('eat_healthy', 'Eat Healthy'),
    ]

    ACTIVITY_CHOICES = [
        ('sedentary', 'Sedentary'),
        ('light', 'Light'),
        ('moderate', 'Moderate'),
        ('active', 'Active'),
        ('very_active', 'Very Active'),
    ]

    GENDER_CHOICES = [
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
    ]

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name='profile')

    # Basic info
    gender = models.CharField(
        max_length=10, choices=GENDER_CHOICES, blank=True, default='')
    date_of_birth = models.DateField(null=True, blank=True)
    weight = models.FloatField(null=True, blank=True)
    height = models.FloatField(null=True, blank=True)
    goal = models.CharField(
        max_length=20, choices=GOAL_CHOICES, default='eat_healthy')
    activity_level = models.CharField(
        max_length=20, choices=ACTIVITY_CHOICES, default='moderate')

    # Medical conditions
    is_diabetic = models.BooleanField(default=False)
    has_hypertension = models.BooleanField(default=False)
    is_celiac = models.BooleanField(default=False)
    is_lactose_intolerant = models.BooleanField(default=False)
    is_vegan = models.BooleanField(default=False)
    is_vegetarian = models.BooleanField(default=False)

    # Allergies & restrictions
    allergies = models.TextField(blank=True, default='')

    # Daily nutritional targets (manual override)
    daily_calories = models.FloatField(null=True, blank=True)
    daily_protein = models.FloatField(null=True, blank=True)
    daily_carbs = models.FloatField(null=True, blank=True)
    daily_fat = models.FloatField(null=True, blank=True)
    daily_sugar_limit = models.FloatField(null=True, blank=True)
    daily_salt_limit = models.FloatField(null=True, blank=True)

    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} - Profile"

    @property
    def age(self):
        if not self.date_of_birth:
            return None
        return (date.today() - self.date_of_birth).days // 365

    @property
    def bmi(self):
        if self.weight and self.height:
            return round(self.weight / (self.height / 100) ** 2, 2)
        return None

    @property
    def daily_calorie_target(self):
        """Mifflin-St Jeor formula. Returns manual override if set."""
        if self.daily_calories:
            return self.daily_calories
        if not self.weight or not self.height or not self.age:
            return None
        bmr = 10 * self.weight + 6.25 * self.height - 5 * self.age
        bmr += 5 if self.gender != 'female' else -161
        multipliers = {
            'sedentary': 1.2,
            'light': 1.375,
            'moderate': 1.55,
            'active': 1.725,
            'very_active': 1.9,
        }
        return round(bmr * multipliers.get(self.activity_level, 1.55))


class HealthSnapshot(models.Model):
    """Periodic health measurement — used to track history (NL-28) and baseline (NL-31)."""
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='health_snapshots')
    weight = models.FloatField(null=True, blank=True)
    bmi = models.FloatField(null=True, blank=True)
    daily_calorie_target = models.FloatField(null=True, blank=True)
    notes = models.TextField(blank=True, default='')
    recorded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-recorded_at']

    def __str__(self):
        return f"{self.user.username} - snapshot {self.recorded_at:%Y-%m-%d}"


class MedicalDocument(models.Model):
    """Medical documents uploaded by the user (NL-29/30)."""
    TYPE_CHOICES = [
        ('blood_test', 'Blood Test'),
        ('prescription', 'Prescription'),
        ('report', 'Medical Report'),
        ('other', 'Other'),
    ]

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='medical_documents')
    title = models.CharField(max_length=255)
    document_type = models.CharField(
        max_length=20, choices=TYPE_CHOICES, default='other')
    file = models.FileField(upload_to='medical_documents/')
    notes = models.TextField(blank=True, default='')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-uploaded_at']

    def __str__(self):
        return f"{self.user.username} - {self.title}"
