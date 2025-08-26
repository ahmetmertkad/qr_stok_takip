from rest_framework import serializers
from .models import Device, Notification

class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = ["id", "token", "platform", "created_at"]

    # Aynı token tekrar gelirse user & platform’u günceller
    def create(self, validated_data):
        user = self.context["request"].user
        obj, _ = Device.objects.update_or_create(
            token=validated_data["token"],
            defaults={"platform": validated_data["platform"], "user": user},
        )
        return obj

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "title", "body", "data", "is_read", "created_at"]
