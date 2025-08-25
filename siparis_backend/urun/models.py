from django.db import models
from django.contrib.auth.models import User  # <-- düzeltildi

class Urun(models.Model):
    DURUM_SECENEKLERI = [
        ('stokta', 'Stokta'),
        ('satildi', 'Satıldı'),
        ('incelemede', 'İncelemede'),
        ('hasarli', 'Hasarlı'),
        ('iade', 'İade'),
        ('rezerve', 'Rezerve'),
        ('silindi', 'Silindi'),
    ]

    ad = models.CharField(max_length=100)
    model_no = models.CharField(max_length=50)
    stok_kodu = models.CharField(max_length=50, unique=True)
    qr_kod = models.ImageField(upload_to='qr_kodlari/', null=True, blank=True)
    durum = models.CharField(max_length=15, choices=DURUM_SECENEKLERI, default='stokta')

    def __str__(self):
        return f"{self.ad} - {self.model_no} - {self.stok_kodu} [{self.durum}]"

    @property
    def sayisi(self):
        return Urun.objects.filter(ad=self.ad, model_no=self.model_no).count()

    @property
    def model_sayisi(self):
        return Urun.objects.filter(model_no=self.model_no).count()


from django.conf import settings  # <-- doğru kullanım

class UrunDurumGecmisi(models.Model):
    urun = models.ForeignKey(Urun, on_delete=models.CASCADE, related_name='durum_gecmisi')
    onceki_durum = models.CharField(null=True,blank=True,max_length=15, choices=Urun.DURUM_SECENEKLERI)
    yeni_durum = models.CharField(max_length=15, choices=Urun.DURUM_SECENEKLERI)
    aciklama = models.TextField(blank=True)
    tarih = models.DateTimeField(auto_now_add=True)
    yapan = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return f"{self.urun} | {self.onceki_durum} → {self.yeni_durum} @ {self.tarih.strftime('%Y-%m-%d %H:%M')}"

