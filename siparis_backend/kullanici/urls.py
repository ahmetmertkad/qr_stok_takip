from django.urls import path
from .views import KayitView, GirisView
from .views import kullanici_listesi
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DurumGuncelleViewSet 
from .views import RolGuncelleViewSet

router = DefaultRouter()
router.register(r'durum', DurumGuncelleViewSet, basename='durum')
router.register(r'rol', RolGuncelleViewSet, basename='rol')

urlpatterns = [
    path("kayit/", KayitView.as_view(), name="kayit"),
    path("giris/", GirisView.as_view(), name="giris"),
    path("kullanici_listesi/",kullanici_listesi),
    path('', include(router.urls)),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/yenile/', TokenRefreshView.as_view(), name='token_refresh'),
]
