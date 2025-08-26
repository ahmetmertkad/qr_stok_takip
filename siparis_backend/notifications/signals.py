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
    """
    Öncelik: role='yonetici' (uygulama içi yönetici)
    Yedek: is_superuser=True (Django superuser)
    """
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
        return  # hedef yoksa sessizce çık

    # DB commit'inden SONRA FCM yollayalım (duplicateları ve rollback sorunlarını önler)
    def _do():
        # 1) DB bildirimi
        Notification.objects.bulk_create([
            Notification(user=u, title=title, body=body, data=data)
            for u in admins
        ], batch_size=1000)

        # 2) FCM push
        tokens = list(
            Device.objects.filter(user__in=admins)
            .values_list("token", flat=True)
            .distinct()
        )
        if tokens:
            try:
                send_to_tokens(tokens, title, body, data)
            except Exception:
                # Push hatası uygulamayı çökertmesin
                pass

    transaction.on_commit(_do)
