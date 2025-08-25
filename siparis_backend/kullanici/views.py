from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from .serializers import KayitSerializer
from .models import CustomUser

class KayitView(APIView):
    permission_classes=[]
    authentication_classes=[]  # JWT kontrol etmesin
    def post(self, request):
        serializer = KayitSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"mesaj": "Kayıt başarılı!"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from django.contrib.auth import authenticate

class GirisView(APIView):
    permission_classes = []
    authentication_classes = []  # login'de JWT arama

    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")

        # 1) kullanıcı var mı?
        user = User.objects.filter(username=username).first()
        if not user:
            return Response({"mesaj": "Geçersiz bilgiler"}, status=status.HTTP_401_UNAUTHORIZED)

        # 2) şifre doğru mu?
        if not user.check_password(password):
            return Response({"mesaj": "Geçersiz bilgiler"}, status=status.HTTP_401_UNAUTHORIZED)

        # 3) aktif mi?
        if not user.is_active:
            return Response(
                {"mesaj": "Hesabınız onaylı değil, yönetici onayı bekliyor"},
                status=status.HTTP_403_FORBIDDEN
            )

        # 4) token üret
        refresh = RefreshToken.for_user(user)
        return Response({
            "mesaj": "Giriş başarılı!",
            "kullanici": {"username": user.username, "role": getattr(user, "role", None)},
            "access": str(refresh.access_token),
            "refresh": str(refresh),
        }, status=status.HTTP_200_OK)

    

from rest_framework.permissions import BasePermission
from rest_framework.views import APIView
from rest_framework.response import Response
from django.contrib.auth import get_user_model

User = get_user_model()

# Özel yetki sınıfı
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import BasePermission
from rest_framework.response import Response
from .models import CustomUser

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import BasePermission
from rest_framework.response import Response
from .models import CustomUser

class IsYoneticiUser(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user and 
            request.user.is_authenticated and 
            request.user.role == 'yonetici'
        )

@api_view(['GET'])
@permission_classes([IsYoneticiUser])
def kullanici_listesi(request):
    users = CustomUser.objects.exclude(id=request.user.id)  # <<< kendini hariç tut
    data = [{
        'id': user.id,
        'username': user.username,
        'role': user.role,
        'is_active': user.is_active
    } for user in users]
    return Response(data)

from rest_framework_simplejwt.tokens import RefreshToken







# views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import CustomUser
from .serializers import RolGuncelleSerializer

@api_view(['PUT'])  # veya PATCH da olur
@permission_classes([IsAuthenticated])  # sadece giriş yapanlar erişebilir
def rol_guncelle(request, user_id):
    try:
        user = CustomUser.objects.get(id=user_id)
    except CustomUser.DoesNotExist:
        return Response({'mesaj': 'Kullanıcı bulunamadı'}, status=status.HTTP_404_NOT_FOUND)

    serializer = RolGuncelleSerializer(instance=user, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response({'mesaj': 'Rol güncellendi', 'kullanici': serializer.data})
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



from rest_framework import viewsets, status, permissions
from rest_framework.response import Response
from .models import CustomUser
from .serializers import DurumGuncelle
from .permissions import IsYoneticiUser  # Eğer özel permission yazdıysan

class DurumGuncelleViewSet(viewsets.ViewSet):
    permission_classes = [IsYoneticiUser]

    def update(self, request, pk=None):
        try:
            user = CustomUser.objects.get(pk=pk)
        except CustomUser.DoesNotExist:
            return Response(
                {"hata": "Kullanıcı bulunamadı"},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = DurumGuncelle(instance=user, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"mesaj": "Durum güncellendi", "kullanici": serializer.data},
                status=status.HTTP_200_OK
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class RolGuncelleViewSet(viewsets.ViewSet):
    permission_classes=[IsYoneticiUser]
    def update(self,request,pk=None):
        try:
            user=CustomUser.objects.get(pk=pk)
        except CustomUser.DoesNotExist:
            return Response(
                {"hata": "Kullanıcı bulunamadı"},
                status=status.HTTP_404_NOT_FOUND
            )
     
        serializer = RolGuncelleSerializer(instance=user, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"mesaj": "Rol güncellendi", "kullanici": serializer.data},
                status=status.HTTP_200_OK
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


