# notifications/signals.py
from django.db import transaction
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model

from urun.models import Urun
from .models import Notification, Device
from .services import send_to_tokens

User = get_user_model()

def _yonetici_queryset():
    qs = User.objects.filter(is_active=True, role="yonetici")
    if qs.exists():
        return qs
    return User.objects.filter(is_active=True, is_superuser=True)

@receiver(post_save, sender=Urun)
def notify_admins_on_urun_create(sender, instance: Urun, created: bool, **kwargs):
    if not created:
        return

    title = "Yeni Ürün Eklendi"
    body = f"{instance.ad} / {instance.model_no} • {instance.stok_kodu}"
    data = {
        "type": "urun_ekleme",
        "urun_id": instance.id,
        "stok_kodu": instance.stok_kodu,
        "durum": getattr(instance, "durum", ""),
    }

    admins = list(_yonetici_queryset())
    if not admins:
        print("[notifications] hedef kullanıcı bulunamadı (yonetici/superuser yok)")
        return

    def _do():
        # DB bildirimi
        Notification.objects.bulk_create([
            Notification(user=u, title=title, body=body, data=data)
            for u in admins
        ], batch_size=1000)

        tokens = list(
            Device.objects.filter(user__in=admins)
            .values_list("token", flat=True)
            .distinct()
        )
        print(f"[notifications] admin_sayisi={len(admins)} token_sayisi={len(tokens)}")

        if tokens:
            try:
                report = send_to_tokens(tokens, title, body, data)
                print(f"[notifications] FCM report: {report}")
            except Exception as e:
                import traceback; traceback.print_exc()
        else:
            print("[notifications] gönderilecek token yok")

    transaction.on_commit(_do)
