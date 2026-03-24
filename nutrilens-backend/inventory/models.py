from django.db import models
from django.contrib.auth.models import User


class InventoryItem(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='inventory')
    
    # Product info from Open Food Facts
    barcode = models.CharField(max_length=50)
    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=255, blank=True, default='')
    image_url = models.URLField(blank=True, default='')
    nutriscore = models.CharField(max_length=1, blank=True, default='')

    # Nutrition per 100g
    calories = models.FloatField(null=True, blank=True)
    fat = models.FloatField(null=True, blank=True)
    saturated_fat = models.FloatField(null=True, blank=True)
    carbohydrates = models.FloatField(null=True, blank=True)
    sugar = models.FloatField(null=True, blank=True)
    fiber = models.FloatField(null=True, blank=True)
    protein = models.FloatField(null=True, blank=True)
    salt = models.FloatField(null=True, blank=True)

    # Inventory management
    quantity = models.PositiveIntegerField(default=1)
    unit = models.CharField(max_length=20, default='unit')
    low_stock_threshold = models.PositiveIntegerField(default=2)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['user', 'barcode']
        ordering = ['-updated_at']

    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.quantity})"

    @property
    def is_low_stock(self):
        return self.quantity <= self.low_stock_threshold