# notifications/serializers.py
from rest_framework import serializers
from .models import Device, Notification

class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = ["id", "token", "platform", "created_at"]
        # <- UniqueValidator'ı kapat (DB'de unique kalsın, biz update_or_create yapacağız)
        extra_kwargs = {
            "token": {"validators": []}
        }

    # Aynı token tekrar gelirse user & platform’u günceller (idempotent)
    def create(self, validated_data):
        user = self.context["request"].user
        obj, _ = Device.objects.update_or_create(
            token=validated_data["token"],
            defaults={"platform": validated_data["platform"], "user": user},
        )
        # DRF'in response'da objeyi göstermesi için:
        self.instance = obj
        return obj


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "title", "body", "data", "is_read", "created_at"]
