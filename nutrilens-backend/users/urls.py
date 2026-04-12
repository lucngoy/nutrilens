from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, ProfileView, AvatarUploadView, TokenObtainPairView,
    ChangePasswordView, HealthSnapshotListView, MedicalDocumentListView,
    MedicalDocumentUploadView, MedicalDocumentDetailView,
    ProductAnalysisView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', TokenObtainPairView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('profile/avatar/', AvatarUploadView.as_view(), name='avatar_upload'),
    path('profile/change-password/', ChangePasswordView.as_view(), name='change_password'),

    # Health history & baseline (NL-28, NL-31)
    path('health/snapshots/', HealthSnapshotListView.as_view(), name='health_snapshots'),

    # Medical documents (NL-29, NL-30)
    path('health/documents/', MedicalDocumentListView.as_view(), name='medical_documents'),
    path('health/documents/upload/', MedicalDocumentUploadView.as_view(), name='medical_document_upload'),
    path('health/documents/<int:pk>/', MedicalDocumentDetailView.as_view(), name='medical_document_detail'),

    # Product analysis — NL-23 to NL-26
    path('health/analyze/', ProductAnalysisView.as_view(), name='product_analysis'),
]
