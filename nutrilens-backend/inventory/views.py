from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import InventoryItem, ScanHistory
from .serializers import InventoryItemSerializer, ScanHistorySerializer
import requests
from django.http import JsonResponse


# Inventory Views
class InventoryListView(generics.ListAPIView):
    serializer_class = InventoryItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        inventory_type = self.request.query_params.get('type', None)
        queryset = InventoryItem.objects.filter(user=self.request.user)
        if inventory_type in ['personal', 'family']:
            queryset = queryset.filter(inventory_type=inventory_type)
        return queryset


class InventoryAddView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        barcode = request.data.get('barcode')
        if not barcode:
            return Response({'error': 'Barcode is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        inventory_type = request.data.get('inventory_type', 'personal')

        item, created = InventoryItem.objects.get_or_create(
            user=request.user,
            barcode=barcode,
            inventory_type=inventory_type,
            defaults={
                'name': request.data.get('name', 'Unknown'),
                'brand': request.data.get('brand', ''),
                'image_url': request.data.get('image_url', ''),
                'nutriscore': request.data.get('nutriscore', ''),
                'calories': request.data.get('calories'),
                'fat': request.data.get('fat'),
                'saturated_fat': request.data.get('saturated_fat'),
                'carbohydrates': request.data.get('carbohydrates'),
                'sugar': request.data.get('sugar'),
                'fiber': request.data.get('fiber'),
                'protein': request.data.get('protein'),
                'salt': request.data.get('salt'),
                'quantity': request.data.get('quantity', 1),
                'unit': request.data.get('unit', 'pieces'),
                'category': request.data.get('category', ''),
                'storage_location': request.data.get('storage_location', ''),
                'expiration_date': request.data.get('expiration_date'),
                'notes': request.data.get('notes', ''),
            }
        )

        if not created:
            item.quantity += int(request.data.get('quantity', 1))
            item.save()

        serializer = InventoryItemSerializer(item)
        return Response(serializer.data,
                        status=status.HTTP_201_CREATED if created
                        else status.HTTP_200_OK)


class InventoryUpdateView(generics.UpdateAPIView):
    serializer_class = InventoryItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return InventoryItem.objects.filter(user=self.request.user)

    def patch(self, request, *args, **kwargs):
        instance = self.get_object()
        quantity = request.data.get('quantity')
        if quantity is not None:
            instance.quantity = max(0, int(quantity))
        for field in ('unit', 'category', 'storage_location', 'expiration_date', 'notes'):
            if field in request.data:
                setattr(instance, field, request.data[field])
        instance.save()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class InventoryDeleteView(generics.DestroyAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return InventoryItem.objects.filter(user=self.request.user)
    
class ProductLookupView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, barcode):
        try:
            response = requests.get(
                f'https://world.openfoodfacts.org/api/v0/product/{barcode}.json',
                timeout=10,
                headers={'User-Agent': 'NutriLens/1.0'}
            )
            return JsonResponse(response.json())
        except requests.exceptions.Timeout:
            return JsonResponse({'error': 'Request timeout'}, status=408)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
        

class ScanHistoryListView(generics.ListAPIView):
    serializer_class = ScanHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        limit = self.request.query_params.get('limit', 10)
        return ScanHistory.objects.filter(
            user=self.request.user)[:int(limit)]


# Scan History Views
class ScanHistoryAddView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ScanHistorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data,
                            status=status.HTTP_201_CREATED)
        return Response(serializer.errors,
                        status=status.HTTP_400_BAD_REQUEST)