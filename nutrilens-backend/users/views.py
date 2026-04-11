from django.contrib.auth.models import User
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import HealthSnapshot, MedicalDocument
from .serializers import (
    RegisterSerializer, UserSerializer, UserProfileSerializer,
    HealthSnapshotSerializer, MedicalDocumentSerializer,
)


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class AvatarUploadView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def patch(self, request):
        profile = request.user.profile
        file = request.FILES.get('avatar')
        if not file:
            return Response({'error': 'No file provided'},
                            status=status.HTTP_400_BAD_REQUEST)
        profile.avatar = file
        profile.save()
        serializer = UserProfileSerializer(profile)
        return Response(serializer.data)


# NL-28 / NL-31 — Health history & baseline
class HealthSnapshotListView(generics.ListCreateAPIView):
    serializer_class = HealthSnapshotSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return HealthSnapshot.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        # Auto-fill bmi and calorie target from current profile if not provided
        profile = self.request.user.profile
        serializer.save(
            user=self.request.user,
            bmi=serializer.validated_data.get('bmi') or profile.bmi,
            daily_calorie_target=(
                serializer.validated_data.get('daily_calorie_target')
                or profile.daily_calorie_target
            ),
        )


# NL-29 / NL-30 — Medical documents
class MedicalDocumentListView(generics.ListAPIView):
    serializer_class = MedicalDocumentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return MedicalDocument.objects.filter(user=self.request.user)


class MedicalDocumentUploadView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = MedicalDocumentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MedicalDocumentDeleteView(generics.DestroyAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return MedicalDocument.objects.filter(user=self.request.user)
