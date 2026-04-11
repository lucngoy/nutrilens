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
        tdee = bmr * multipliers.get(self.activity_level, 1.55)
        goal_adjustments = {
            'lose_weight': -500,
            'gain_muscle': +300,
            'maintain': 0,
            'eat_healthy': 0,
        }
        adjustment = goal_adjustments.get(self.goal, 0)
        return round(tdee + adjustment)

    # g/kg body weight per goal — scientifically grounded
    _MACRO_PER_KG = {
        #                protein  fat   sugar_%calories  salt
        'lose_weight':  (2.0,    0.9,  0.05,            5),
        'gain_muscle':  (1.8,    0.9,  0.10,            6),
        'maintain':     (1.2,    1.0,  0.10,            5),
        'eat_healthy':  (1.2,    0.9,  0.05,            5),
    }

    def _macros_from_weight(self):
        """Returns (protein_g, fat_g, carbs_g, sugar_g, salt_g) or None."""
        if not self.weight or not self.daily_calorie_target:
            return None
        kcal = self.daily_calorie_target
        protein_per_kg, fat_per_kg, sugar_pct, salt = self._MACRO_PER_KG.get(
            self.goal, self._MACRO_PER_KG['maintain'])

        protein_g = round(self.weight * protein_per_kg)
        fat_g = round(self.weight * fat_per_kg)

        # Remaining calories go to carbs
        remaining = kcal - (protein_g * 4) - (fat_g * 9)
        carbs_g = round(max(remaining, 0) / 4)

        # Sugar: % of total calories (OMS <10%, strict goals <5%)
        sugar_g = round(kcal * sugar_pct / 4)

        return protein_g, fat_g, carbs_g, sugar_g, salt

    @property
    def protein_target(self):
        if self.daily_protein:
            return self.daily_protein
        macros = self._macros_from_weight()
        return macros[0] if macros else None

    @property
    def fat_target(self):
        if self.daily_fat:
            return self.daily_fat
        macros = self._macros_from_weight()
        return macros[1] if macros else None

    @property
    def carbs_target(self):
        if self.daily_carbs:
            return self.daily_carbs
        macros = self._macros_from_weight()
        return macros[2] if macros else None

    @property
    def sugar_limit_target(self):
        if self.daily_sugar_limit:
            return self.daily_sugar_limit
        macros = self._macros_from_weight()
        return macros[3] if macros else None

    @property
    def salt_limit_target(self):
        if self.daily_salt_limit:
            return self.daily_salt_limit
        macros = self._macros_from_weight()
        return macros[4] if macros else None


class HealthSnapshot(models.Model):
    """Periodic health measurement — used to track history (NL-28) and baseline (NL-31)."""
    SOURCE_CHOICES = [
        ('auto', 'Auto'),
        ('manual', 'Manual'),
    ]

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='health_snapshots')
    weight = models.FloatField(null=True, blank=True)
    bmi = models.FloatField(null=True, blank=True)
    daily_calorie_target = models.FloatField(null=True, blank=True)
    notes = models.TextField(blank=True, default='')
    source = models.CharField(
        max_length=10, choices=SOURCE_CHOICES, default='manual')
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
