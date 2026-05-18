from rest_framework import generics, permissions, status, parsers
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import InventoryItem, ScanHistory, UserProduct, UserProductVote
from .serializers import InventoryItemSerializer, ScanHistorySerializer, UserProductSerializer, UserProductVoteSerializer
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
                'name': request.data.get('name', 'Unknown')[:255],
                'brand': request.data.get('brand', '')[:255],
                'image_url': (request.data.get('image_url', '') or '')[:500],
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
                'consumption_per_use': request.data.get('consumption_per_use'),
                'uses_per_week': request.data.get('uses_per_week'),
            }
        )

        if not created:
            item.quantity += int(request.data.get('quantity', 1))
            if request.data.get('consumption_per_use') is not None:
                item.consumption_per_use = request.data.get('consumption_per_use')
            if request.data.get('uses_per_week') is not None:
                item.uses_per_week = request.data.get('uses_per_week')
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
        for field in ('unit', 'category', 'storage_location', 'expiration_date', 'notes', 'consumption_per_use', 'uses_per_week'):
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
        # Priority 1: own product (any non-rejected status)
        up = UserProduct.objects.filter(
            user=request.user, barcode=barcode
        ).exclude(status='rejected').first()

        # Priority 2: any non-rejected contribution from any user
        # Prefer approved > community_verified > pending so others can vote
        if up is None:
            from django.db.models import Case, IntegerField, Value, When
            up = UserProduct.objects.filter(
                barcode=barcode
            ).exclude(status='rejected').annotate(
                status_order=Case(
                    When(status='approved', then=Value(0)),
                    When(status='community_verified', then=Value(1)),
                    default=Value(2),
                    output_field=IntegerField(),
                )
            ).order_by('status_order', '-confirmation_count').first()

        if up is not None:
            image_url = request.build_absolute_uri(up.image.url) if up.image else None
            return JsonResponse({
                'status': 1,
                'source': 'user',
                'user_product_id': up.id,
                'user_product_status': up.status,
                'user_product_is_owner': up.user == request.user,
                'product': {
                    'code': up.barcode,
                    'product_name': up.name,
                    'brands': up.brand,
                    'image_url': image_url,
                    'nutriscore_grade': None,
                    'allergens_tags': [],
                    'ingredients': [],
                    'nutriments': {
                        'energy-kcal_100g': up.calories,
                        'proteins_100g': up.protein,
                        'carbohydrates_100g': up.carbohydrates,
                        'fat_100g': up.fat,
                        'sugars_100g': up.sugar,
                        'salt_100g': up.salt,
                        'saturated-fat_100g': None,
                        'fiber_100g': None,
                    },
                }
            })

        # Fall back to OpenFoodFacts
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


class UserProductListCreateView(generics.ListCreateAPIView):
    serializer_class = UserProductSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.JSONParser]

    def get_queryset(self):
        return UserProduct.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class UserProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = UserProductSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.JSONParser]

    def get_queryset(self):
        return UserProduct.objects.filter(user=self.request.user)


class UserProductVoteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            product = UserProduct.objects.get(pk=pk)
        except UserProduct.DoesNotExist:
            return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)

        if product.user == request.user:
            return Response({'error': 'You cannot vote on your own product'},
                            status=status.HTTP_400_BAD_REQUEST)

        vote_type = request.data.get('vote')
        if vote_type not in ('confirm', 'flag'):
            return Response({'error': 'vote must be "confirm" or "flag"'},
                            status=status.HTTP_400_BAD_REQUEST)

        UserProductVote.objects.update_or_create(
            user=request.user,
            product=product,
            defaults={'vote': vote_type},
        )

        product.confirmation_count = product.votes.filter(vote='confirm').count()
        product.flag_count = product.votes.filter(vote='flag').count()
        product.save(update_fields=['confirmation_count', 'flag_count'])
        product.update_status()

        return Response({
            'status': product.status,
            'confirmation_count': product.confirmation_count,
            'flag_count': product.flag_count,
            'your_vote': vote_type,
        })
        

class AdminProductReviewListView(APIView):
    """Staff-only: list products pending admin review."""
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        status_filter = request.query_params.get('status', 'pending')
        qs = UserProduct.objects.filter(status=status_filter).select_related('user')
        data = []
        for p in qs:
            data.append({
                'id': p.id,
                'name': p.name,
                'brand': p.brand,
                'barcode': p.barcode,
                'image': request.build_absolute_uri(p.image.url) if p.image else None,
                'calories': p.calories,
                'protein': p.protein,
                'carbohydrates': p.carbohydrates,
                'fat': p.fat,
                'sugar': p.sugar,
                'salt': p.salt,
                'serving_size': p.serving_size,
                'serving_unit': p.serving_unit,
                'status': p.status,
                'confirmation_count': p.confirmation_count,
                'flag_count': p.flag_count,
                'submitted_by': p.user.username,
                'created_at': p.created_at.isoformat(),
            })
        return Response(data)


class AdminPendingCountView(APIView):
    """Staff-only: count of products needing review (pending + community_verified)."""
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        count = UserProduct.objects.filter(
            status__in=['pending', 'community_verified']
        ).count()
        community = UserProduct.objects.filter(status='community_verified').count()
        return Response({'total': count, 'community_verified': community})


class AdminProductReviewActionView(APIView):
    """Staff-only: approve or reject a single product."""
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk):
        action = request.data.get('action')
        if action not in ('approve', 'reject', 'pending'):
            return Response({'error': 'action must be approve, reject, or pending'},
                            status=status.HTTP_400_BAD_REQUEST)
        try:
            product = UserProduct.objects.get(pk=pk)
        except UserProduct.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        product.status = {'approve': 'approved', 'reject': 'rejected', 'pending': 'pending'}[action]
        product.save(update_fields=['status'])
        return Response({'id': product.id, 'status': product.status})


class ScanHistoryListView(generics.ListAPIView):
    serializer_class = ScanHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        limit = self.request.query_params.get('limit', 10)
        return ScanHistory.objects.filter(
            user=self.request.user)[:int(limit)]


class ProductSearchView(APIView):
    """Search OpenFoodFacts by product name, return top results."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        q = (request.query_params.get('q') or '').strip()
        if not q:
            return Response({'error': 'q is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            response = requests.get(
                'https://world.openfoodfacts.org/cgi/search.pl',
                params={
                    'search_terms': q,
                    'search_simple': 1,
                    'action': 'process',
                    'json': 1,
                    'page_size': 5,
                    'fields': 'code,product_name,brands,nutriscore_grade,image_url,nutriments,ingredients_text,allergens_tags',
                },
                timeout=12,
                headers={'User-Agent': 'NutriLens/1.0'},
                allow_redirects=True,
            )
            # Don't raise_for_status — parse whatever we got
            try:
                data = response.json()
            except ValueError:
                return Response({'products': []})  # non-JSON response → empty results
            products = []
            for p in (data.get('products') or []):
                name = (p.get('product_name') or '').strip()
                code = (p.get('code') or '').strip()
                if not name or not code:
                    continue
                products.append({
                    'code': code,
                    'product_name': name,
                    'brands': p.get('brands', ''),
                    'nutriscore_grade': p.get('nutriscore_grade') or None,
                    'image_url': p.get('image_url') or None,
                    'nutriments': p.get('nutriments') or {},
                    'ingredients_text': p.get('ingredients_text', ''),
                    'allergens_tags': p.get('allergens_tags') or [],
                })
            return Response({'products': products})
        except requests.exceptions.Timeout:
            return Response({'error': 'Search timed out — try again'}, status=status.HTTP_408_REQUEST_TIMEOUT)
        except requests.exceptions.HTTPError as e:
            return Response({'error': f'OpenFoodFacts error: {e}'}, status=status.HTTP_502_BAD_GATEWAY)
        except (ValueError, KeyError) as e:
            return Response({'error': f'Unexpected response format: {e}'}, status=status.HTTP_502_BAD_GATEWAY)
        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class QuickAddInventoryView(APIView):
    """Add an inventory item by name only (no barcode required — receipt import)."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        import uuid
        name = (request.data.get('name') or '').strip()[:255]
        if not name:
            return Response({'error': 'name is required'}, status=status.HTTP_400_BAD_REQUEST)

        # Generate a unique barcode so unique_together constraint is satisfied
        barcode = f'RCPT-{uuid.uuid4().hex[:12].upper()}'
        inventory_type = request.data.get('inventory_type', 'personal')

        item = InventoryItem.objects.create(
            user=request.user,
            barcode=barcode,
            inventory_type=inventory_type,
            name=name,
            quantity=int(request.data.get('quantity', 1)),
            unit=request.data.get('unit', 'pieces'),
            category=request.data.get('category', ''),
            notes=request.data.get('notes', ''),
        )

        # Link back to ReceiptLine if provided
        line_id = request.data.get('receipt_line_id')
        if line_id:
            try:
                from budget.models import ReceiptLine
                rl = ReceiptLine.objects.get(id=line_id, receipt__user=request.user)
                rl.matched_inventory_item = item
                rl.match_confirmed = True
                rl.confidence_score = 1.0
                rl.save(update_fields=['matched_inventory_item', 'match_confirmed', 'confidence_score'])
            except Exception:
                pass

        return Response(InventoryItemSerializer(item).data, status=status.HTTP_201_CREATED)


# Scan History Views
class ScanHistoryAddView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        data = request.data.copy()
        if 'image_url' in data:
            data['image_url'] = (data['image_url'] or '')[:500]
        if 'name' in data:
            data['name'] = (data['name'] or '')[:255]
        if 'brand' in data:
            data['brand'] = (data['brand'] or '')[:255]
        serializer = ScanHistorySerializer(data=data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data,
                            status=status.HTTP_201_CREATED)
        return Response(serializer.errors,
                        status=status.HTTP_400_BAD_REQUEST)