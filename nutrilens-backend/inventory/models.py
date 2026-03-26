from django.db import models
from django.contrib.auth.models import User


class InventoryItem(models.Model):

    CATEGORY_CHOICES = [
        ('fruits', 'Fruits'),
        ('vegetables', 'Vegetables'),
        ('dairy', 'Dairy'),
        ('meat', 'Meat'),
        ('snacks', 'Snacks'),
        ('beverages', 'Beverages'),
        ('grains', 'Grains'),
        ('other', 'Other'),
    ]

    STORAGE_CHOICES = [
        ('refrigerator', 'Refrigerator'),
        ('freezer', 'Freezer'),
        ('pantry', 'Pantry'),
        ('cabinet', 'Cabinet'),
    ]

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

    # Extra fields
    category = models.CharField(
        max_length=20, choices=CATEGORY_CHOICES, blank=True, default='other')
    storage_location = models.CharField(
        max_length=20, choices=STORAGE_CHOICES, blank=True, default='')
    expiration_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True, default='')

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

class ScanHistory(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='scan_history')
    barcode = models.CharField(max_length=50)
    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=255, blank=True, default='')
    image_url = models.URLField(blank=True, default='')
    nutriscore = models.CharField(max_length=1, blank=True, default='')
    calories = models.FloatField(null=True, blank=True)
    scanned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-scanned_at']

    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.scanned_at})"