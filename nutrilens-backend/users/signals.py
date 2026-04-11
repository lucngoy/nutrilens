from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import UserProfile, HealthSnapshot


@receiver(post_save, sender=UserProfile)
def create_health_snapshot(sender, instance, created, **kwargs):
    """Create a HealthSnapshot every time the UserProfile is saved (NL-31)."""
    # Only snapshot if we have meaningful data
    if instance.weight or instance.bmi or instance.daily_calorie_target:
        HealthSnapshot.objects.create(
            user=instance.user,
            weight=instance.weight,
            bmi=instance.bmi,
            daily_calorie_target=instance.daily_calorie_target,
        )
