from rest_framework import serializers
from .models import InventoryItem


class InventoryItemSerializer(serializers.ModelSerializer):
    is_low_stock = serializers.ReadOnlyField()

    class Meta:
        model = InventoryItem
        fields = [
            'id', 'barcode', 'name', 'brand', 'image_url', 'nutriscore',
            'calories', 'fat', 'saturated_fat', 'carbohydrates', 'sugar',
            'fiber', 'protein', 'salt', 'quantity', 'unit',
            'low_stock_threshold', 'is_low_stock',
            'category', 'storage_location', 'expiration_date', 'notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']