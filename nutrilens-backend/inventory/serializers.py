from rest_framework import serializers
from .models import InventoryItem, ScanHistory, UserProduct, UserProductVote


class InventoryItemSerializer(serializers.ModelSerializer):
    is_low_stock = serializers.ReadOnlyField()

    class Meta:
        model = InventoryItem
        fields = [
            'id', 'inventory_type', 'barcode', 'name', 'brand', 'image_url', 'nutriscore',
            'calories', 'fat', 'saturated_fat', 'carbohydrates', 'sugar',
            'fiber', 'protein', 'salt', 'quantity', 'unit',
            'low_stock_threshold', 'is_low_stock',
            'category', 'storage_location', 'expiration_date', 'notes',
            'inventory_type',
            'consumption_per_use', 'uses_per_week',
            'daily_consumption', 'days_remaining',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at',
                            'daily_consumption', 'days_remaining']


class UserProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProduct
        fields = [
            'id', 'barcode', 'name', 'brand', 'image',
            'serving_size', 'serving_unit',
            'calories', 'protein', 'carbohydrates', 'fat', 'sugar', 'salt',
            'status', 'confirmation_count', 'flag_count',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'status', 'confirmation_count', 'flag_count', 'created_at', 'updated_at']


class UserProductVoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProductVote
        fields = ['id', 'product', 'vote', 'created_at']
        read_only_fields = ['id', 'created_at']


class ScanHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ScanHistory
        fields = [
            'id', 'barcode', 'name', 'brand', 'image_url',
            'nutriscore', 'calories', 'scanned_at'
        ]
        read_only_fields = ['id', 'scanned_at']