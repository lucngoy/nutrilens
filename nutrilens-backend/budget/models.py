import calendar
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class MonthlyBudget(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='budgets')
    month = models.CharField(max_length=7)  # 'YYYY-MM'
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['user', 'month']
        ordering = ['-month']

    def __str__(self):
        return f"{self.user.username} - {self.month} (${self.amount})"

    @property
    def total_spent(self):
        return float(
            self.entries.aggregate(models.Sum('amount'))['amount__sum'] or 0
        )

    @property
    def remaining(self):
        return float(self.amount) - self.total_spent

    @property
    def percentage_used(self):
        if float(self.amount) == 0:
            return 0.0
        return round((self.total_spent / float(self.amount)) * 100, 1)

    @property
    def daily_budget(self):
        year, month = map(int, self.month.split('-'))
        days = calendar.monthrange(year, month)[1]
        return round(float(self.amount) / days, 2)

    @property
    def avg_daily_spent(self):
        today = timezone.now().date()
        year, month = map(int, self.month.split('-'))
        if today.year == year and today.month == month:
            days_passed = max(today.day, 1)
        else:
            days_passed = calendar.monthrange(year, month)[1]
        return round(self.total_spent / days_passed, 2)

    @property
    def projected_spent(self):
        year, month = map(int, self.month.split('-'))
        days_in_month = calendar.monthrange(year, month)[1]
        return round(self.avg_daily_spent * days_in_month, 2)

    @property
    def pace_status(self):
        amount = float(self.amount)
        if self.total_spent > amount:
            return 'exceeded'
        if self.projected_spent > amount * 0.9:
            return 'warning'
        return 'on_track'


class SpendingEntry(models.Model):
    CATEGORY_CHOICES = [
        ('groceries', 'Groceries'),
        ('restaurant', 'Restaurant'),
        ('snack', 'Snack'),
        ('other', 'Other'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='spending_entries')
    budget = models.ForeignKey(MonthlyBudget, on_delete=models.CASCADE, related_name='entries')
    description = models.CharField(max_length=255)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='groceries')
    date = models.DateField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date', '-created_at']

    def __str__(self):
        return f"{self.user.username} - {self.description} (${self.amount})"
