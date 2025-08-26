from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from .models import Urun
from notifications.models import Device, Notification
from notifications.services import send_to_tokens

User = get_user_model()

@receiver(post_save, sender=Urun)
def urun_eklenince_admin_push(sender, instance: Urun, created, **kwargs):
    if not created:
        return

    title = "Yeni Ürün Eklendi"
    body  = f"{instance.ad} - {instance.model_no}"
    data  = {"urun_id": str(instance.id), "stok_kodu": instance.stok_kodu, "tip": "urun_eklendi"}

    # 1) YÖNETİCİ kullanıcılar (is_staff=True). İstersen is_superuser=True yapabilirsin.
    admin_users = User.objects.filter(is_staff=True)

    # 2) Bu kullanıcılara ait cihaz tokenları
    tokens = list(Device.objects.filter(user__in=admin_users).values_list("token", flat=True))

    # 3) Yalnızca yöneticilere push gönder
    if tokens:
        try:
            send_to_tokens(tokens, title, body, data)
        except Exception as e:
            print("FCM admin push error:", e)

    # 4) Uygulama içi bildirim geçmişi
    if admin_users:
        Notification.objects.bulk_create([
            Notification(user=u, title=title, body=body, data=data)
            for u in admin_users
        ])
