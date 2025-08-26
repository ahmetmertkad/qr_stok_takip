# notifications/urls.py
from rest_framework.routers import DefaultRouter
from .views import DeviceViewSet, NotificationViewSet

router = DefaultRouter()
router.register(r'devices', DeviceViewSet, basename='device')
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = router.urls
