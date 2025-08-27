from rest_framework import viewsets, permissions, mixins
from .models import Device, Notification
from .serializers import DeviceSerializer, NotificationSerializer

# notifications/views.py
from rest_framework.response import Response
from rest_framework import status

class DeviceViewSet(mixins.CreateModelMixin,
                    mixins.ListModelMixin,
                    viewsets.GenericViewSet):
    serializer_class = DeviceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Device.objects.filter(user=self.request.user).order_by("-created_at")

    def create(self, request, *args, **kwargs):
        resp = super().create(request, *args, **kwargs)
        # Başarısızsa hataları ekrana bas
        if resp.status_code >= 400:
            from pprint import pprint
            print("[/api/devices/] HATA:", resp.data)
        return resp


class NotificationViewSet(mixins.ListModelMixin,
                          mixins.UpdateModelMixin,
                          viewsets.GenericViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by("-created_at")
