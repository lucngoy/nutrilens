from django.db import models
from django.contrib.auth.models import User


class UserProfile(models.Model):
    GOAL_CHOICES = [
        ('lose_weight', 'Lose Weight'),
        ('gain_muscle', 'Gain Muscle'),
        ('maintain', 'Maintain'),
        ('eat_healthy', 'Eat Healthy'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    date_of_birth = models.DateField(null=True, blank=True)
    weight = models.FloatField(null=True, blank=True)
    height = models.FloatField(null=True, blank=True)
    goal = models.CharField(max_length=20, choices=GOAL_CHOICES, default='eat_healthy')

    # Conditions médicales
    is_diabetic = models.BooleanField(default=False)
    has_hypertension = models.BooleanField(default=False)
    is_celiac = models.BooleanField(default=False)

    # Allergies (texte libre pour flexibilité)
    allergies = models.TextField(blank=True, default='')

    avatar = models.ImageField(
        upload_to='avatars/',
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} - Profile"

    @property
    def bmi(self):
        if self.weight and self.height:
            return round(self.weight / (self.height / 100) ** 2, 2)
        return None