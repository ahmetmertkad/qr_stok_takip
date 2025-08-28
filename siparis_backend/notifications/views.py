# notifications/views.py
from rest_framework import viewsets, permissions, mixins, decorators
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q
from django.db import IntegrityError, transaction

from .models import Device, Notification
from .serializers import DeviceSerializer, NotificationSerializer

class DeviceViewSet(mixins.CreateModelMixin,
                    mixins.ListModelMixin,
                    viewsets.GenericViewSet):
    serializer_class = DeviceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Device.objects.filter(user=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        """Token unique olduğundan, aynı token gelirse user & platform’u güncelle."""
        token = serializer.validated_data.get("token")
        platform = serializer.validated_data.get("platform")
        try:
            with transaction.atomic():
                # Eğer bu token zaten varsa, sahibini güncelle
                obj, created = Device.objects.update_or_create(
                    token=token,
                    defaults={"user": self.request.user, "platform": platform},
                )
                # CreateModelMixin normalde serializer.save döndürür; biz manuel set ediyoruz
                serializer.instance = obj
        except IntegrityError:
            # Nadir yarış koşulları için emniyet: yeniden dene
            obj = Device.objects.filter(token=token).first()
            if obj:
                obj.user = self.request.user
                obj.platform = platform
                obj.save(update_fields=["user", "platform"])
                serializer.instance = obj
            else:
                serializer.save(user=self.request.user)

    def create(self, request, *args, **kwargs):
        resp = super().create(request, *args, **kwargs)
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
        """
        Kendi bildirimleri + broadcast (user IS NULL).
        /notifications/?is_read=false ile filtrelenebilir.
        """
        u = self.request.user
        qs = Notification.objects.filter(Q(user=u) | Q(user__isnull=True)).order_by("-created_at")

        is_read = self.request.query_params.get("is_read")
        if is_read in ("true", "false"):
            qs = qs.filter(is_read=(is_read == "true"))

        return qs

    @decorators.action(detail=False, methods=["get"], url_path="unread-count")
    def unread_count(self, request):
        u = request.user
        count = Notification.objects.filter(
            Q(user=u) | Q(user__isnull=True),
            is_read=False
        ).count()
        return Response({"unread": count})

    @decorators.action(detail=True, methods=["patch"], url_path="mark-read")
    def mark_read(self, request, pk=None):
        obj = self.get_object()
        if not obj.is_read:
            obj.is_read = True
            obj.save(update_fields=["is_read"])
        return Response({"ok": True})

    @decorators.action(detail=False, methods=["post"], url_path="mark-all-read")
    def mark_all_read(self, request):
        u = request.user
        Notification.objects.filter(
            Q(user=u) | Q(user__isnull=True),
            is_read=False
        ).update(is_read=True)
        return Response({"ok": True}, status=status.HTTP_200_OK)
