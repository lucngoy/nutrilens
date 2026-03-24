from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import InventoryItem
from .serializers import InventoryItemSerializer
import requests
from django.http import JsonResponse


class InventoryListView(generics.ListAPIView):
    serializer_class = InventoryItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return InventoryItem.objects.filter(user=self.request.user)


class InventoryAddView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        barcode = request.data.get('barcode')
        if not barcode:
            return Response({'error': 'Barcode is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        item, created = InventoryItem.objects.get_or_create(
            user=request.user,
            barcode=barcode,
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
            }
        )

        if not created:
            item.quantity += 1
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