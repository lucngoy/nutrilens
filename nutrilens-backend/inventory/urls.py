from django.urls import path
from .views import (
    InventoryListView,
    InventoryAddView,
    InventoryUpdateView,
    InventoryDeleteView,
    ProductLookupView,
    ScanHistoryListView,
    ScanHistoryAddView,
)

urlpatterns = [
    path('', InventoryListView.as_view(), name='inventory-list'),
    path('add/', InventoryAddView.as_view(), name='inventory-add'),
    path('<int:pk>/update/', InventoryUpdateView.as_view(), name='inventory-update'),
    path('<int:pk>/delete/', InventoryDeleteView.as_view(), name='inventory-delete'),
    path('product/<str:barcode>/', ProductLookupView.as_view(), name='product-lookup'),
    path('scans/', ScanHistoryListView.as_view(), name='scan-history-list'),
    path('scans/add/', ScanHistoryAddView.as_view(), name='scan-history-add'),
]
