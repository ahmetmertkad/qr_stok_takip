# urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UrunViewSet, UrunDurumGecmisiViewSet

router = DefaultRouter()
router.register(r"urunler", UrunViewSet, basename="urun")
router.register(r"urun-durum-gecmisi", UrunDurumGecmisiViewSet, basename="urun-durum-gecmisi")

urlpatterns = [
    path('', include(router.urls)),
]
