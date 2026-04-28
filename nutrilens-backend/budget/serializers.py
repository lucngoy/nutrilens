from rest_framework import serializers
from .models import MonthlyBudget, SpendingEntry


class SpendingEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = SpendingEntry
        fields = ['id', 'description', 'amount', 'category', 'date', 'created_at']
        read_only_fields = ['id', 'created_at']


class MonthlyBudgetSerializer(serializers.ModelSerializer):
    total_spent = serializers.ReadOnlyField()
    remaining = serializers.ReadOnlyField()
    percentage_used = serializers.ReadOnlyField()
    daily_budget = serializers.ReadOnlyField()
    avg_daily_spent = serializers.ReadOnlyField()
    projected_spent = serializers.ReadOnlyField()
    pace_status = serializers.ReadOnlyField()
    entries = SpendingEntrySerializer(many=True, read_only=True)

    class Meta:
        model = MonthlyBudget
        fields = [
            'id', 'month', 'amount',
            'total_spent', 'remaining', 'percentage_used',
            'daily_budget', 'avg_daily_spent', 'projected_spent', 'pace_status',
            'entries', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
