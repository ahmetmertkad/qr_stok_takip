# notifications/models.py
from django.db import models
from django.conf import settings

class Device(models.Model):
    PLATFORM_CHOICES = (('android','Android'), ('ios','iOS'), ('web','Web'))
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='devices')
    token = models.CharField(max_length=512, unique=True)  # FCM token (uzun olabilir)
    platform = models.CharField(max_length=10, choices=PLATFORM_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)

class Notification(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications', null=True, blank=True)
    # user NULL ise topic/broadcast bildirimi olarak düşünebilirsin
    title = models.CharField(max_length=120)
    body  = models.TextField(blank=True)
    data  = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
