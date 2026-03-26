from rest_framework import serializers
from .models import InventoryItem, ScanHistory


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
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ScanHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ScanHistory
        fields = [
            'id', 'barcode', 'name', 'brand', 'image_url',
            'nutriscore', 'calories', 'scanned_at'
        ]
        read_only_fields = ['id', 'scanned_at']