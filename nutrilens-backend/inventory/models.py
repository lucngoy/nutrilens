from django.db import models
from django.contrib.auth.models import User


INVENTORY_TYPE_CHOICES = [
    ('personal', 'Personal'),
    ('family', 'Family'),
]


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
    inventory_type = models.CharField(
        max_length=10,
        choices=INVENTORY_TYPE_CHOICES,
        default='personal',
    )

    # Product info from Open Food Facts
    barcode = models.CharField(max_length=50)
    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=255, blank=True, default='')
    image_url = models.URLField(max_length=500, blank=True, default='')
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

    # Consumption planning
    consumption_per_use = models.FloatField(null=True, blank=True)
    uses_per_week = models.FloatField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['user', 'barcode', 'inventory_type']
        ordering = ['-updated_at']

    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.quantity})"

    @property
    def daily_consumption(self):
        """Estimated daily consumption."""
        if self.consumption_per_use and self.uses_per_week:
            return (self.consumption_per_use * self.uses_per_week) / 7
        return None

    @property
    def days_remaining(self):
        """Estimated days before stock runs out."""
        if self.daily_consumption and self.daily_consumption > 0:
            return round(self.quantity / self.daily_consumption, 1)
        return None

    @property
    def is_low_stock(self):
        if self.days_remaining is not None:
            return self.days_remaining <= 3
        return self.quantity <= self.low_stock_threshold

class UserProduct(models.Model):
    """Products created manually by users when not found in OpenFoodFacts."""

    STATUS_CHOICES = [
        ('pending',            'Pending'),
        ('community_verified', 'Community Verified'),
        ('approved',           'Approved'),
        ('rejected',           'Rejected'),
    ]

    COMMUNITY_VERIFY_THRESHOLD = 3
    FLAG_THRESHOLD = 3

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='user_products')
    barcode = models.CharField(max_length=50, blank=True, default='')
    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=255, blank=True, default='')
    image = models.ImageField(upload_to='user_products/', null=True, blank=True)
    serving_size = models.FloatField(default=100)
    serving_unit = models.CharField(max_length=20, default='g')

    # Nutrition per serving
    calories = models.FloatField(null=True, blank=True)
    protein = models.FloatField(null=True, blank=True)
    carbohydrates = models.FloatField(null=True, blank=True)
    fat = models.FloatField(null=True, blank=True)
    sugar = models.FloatField(null=True, blank=True)
    salt = models.FloatField(null=True, blank=True)

    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='pending')
    confirmation_count = models.PositiveIntegerField(default=0)
    flag_count = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.status})"

    def update_status(self):
        if self.status == 'approved' or self.status == 'rejected':
            return
        previous = self.status
        if self.flag_count >= self.FLAG_THRESHOLD:
            self.status = 'pending'
        elif self.confirmation_count >= self.COMMUNITY_VERIFY_THRESHOLD:
            self.status = 'community_verified'
        else:
            self.status = 'pending'
        self.save(update_fields=['status'])
        if self.status == 'community_verified' and previous != 'community_verified':
            self._notify_staff()

    def _notify_staff(self):
        from django.contrib.auth.models import User
        from django.core.mail import send_mail
        staff_emails = list(
            User.objects.filter(is_staff=True, email__isnull=False)
            .exclude(email='')
            .values_list('email', flat=True)
        )
        if not staff_emails:
            return
        try:
            send_mail(
                subject=f'[NutriLens] Product ready for review: {self.name}',
                message=(
                    f'The product "{self.name}" (submitted by {self.user.username}) '
                    f'has reached {self.COMMUNITY_VERIFY_THRESHOLD} community confirmations '
                    f'and is now awaiting your approval.\n\n'
                    f'Log in to the admin panel to approve or reject it.'
                ),
                from_email=None,
                recipient_list=staff_emails,
                fail_silently=True,
            )
        except Exception:
            pass


class UserProductVote(models.Model):
    VOTE_CHOICES = [
        ('confirm', 'Confirm'),
        ('flag',    'Flag'),
    ]
    user    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='product_votes')
    product = models.ForeignKey(UserProduct, on_delete=models.CASCADE, related_name='votes')
    vote    = models.CharField(max_length=10, choices=VOTE_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['user', 'product']

    def __str__(self):
        return f"{self.user.username} — {self.vote} — {self.product.name}"


class ScanHistory(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='scan_history')
    barcode = models.CharField(max_length=50)
    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=255, blank=True, default='')
    image_url = models.URLField(max_length=500, blank=True, default='')
    nutriscore = models.CharField(max_length=1, blank=True, default='')
    calories = models.FloatField(null=True, blank=True)
    scanned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-scanned_at']

    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.scanned_at})"