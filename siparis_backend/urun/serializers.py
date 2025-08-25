from rest_framework import serializers
from .models import Urun, UrunDurumGecmisi
import qrcode
from io import BytesIO
from django.core.files import File

class UrunSerializer(serializers.ModelSerializer):
    class Meta:
        model = Urun
        fields = '__all__'

    def create_qr_kod(self, urun):
        qr_data = f"{urun.ad} - {urun.model_no} - {urun.stok_kodu}"
        qr_img = qrcode.make(qr_data)
        buffer = BytesIO()
        qr_img.save(buffer, format='PNG')
        file_name = f"{urun.ad}_{urun.id}_qr.png"
        urun.qr_kod.save(file_name, File(buffer), save=False)

    def create(self, validated_data):
        adet = self.context['request'].data.get('adet', 1)
        try:
            adet = int(adet)
        except ValueError:
            adet = 1

        urunler = []
        request = self.context.get('request')

        for i in range(adet):
            stok_kodu = f"{validated_data['stok_kodu']}-{i+1}"
            urun = Urun.objects.create(
            ad=validated_data['ad'],
            model_no=validated_data['model_no'],
            stok_kodu=stok_kodu,
        )
            self.create_qr_kod(urun)
            urun.save()

        # 👇 Durum geçmişi kaydı (for döngüsünün içinde)
            UrunDurumGecmisi.objects.create(
    urun=urun,
    onceki_durum=None,   # ilk kayıt, önceki yok
    yeni_durum='stokta', # varsayılan
    aciklama="Ürün oluşturuldu",
    yapan=request.user if request else None
)

            urunler.append(urun)

        return urunler[-1]


    def update(self, instance, validated_data):
        eski_ad = instance.ad
        eski_model_no = instance.model_no
        eski_stok_kodu = instance.stok_kodu

        instance.ad = validated_data.get('ad', instance.ad)
        instance.model_no = validated_data.get('model_no', instance.model_no)
        instance.stok_kodu = validated_data.get('stok_kodu', instance.stok_kodu)

        if (
            instance.ad != eski_ad or
            instance.model_no != eski_model_no or
            instance.stok_kodu != eski_stok_kodu
        ):
            self.create_qr_kod(instance)

        instance.save()
        return instance


class UrunDurumGecmisiSerializer(serializers.ModelSerializer):
    onceki_durum_label = serializers.SerializerMethodField()
    yeni_durum_label = serializers.SerializerMethodField()
    yapan_username = serializers.SerializerMethodField()

    class Meta:
        model = UrunDurumGecmisi
        fields = [
            'id', 'urun',
            'onceki_durum', 'onceki_durum_label',
            'yeni_durum', 'yeni_durum_label',
            'aciklama', 'tarih',
            'yapan', 'yapan_username'
        ]

    def get_onceki_durum_label(self, obj):
        if not obj.onceki_durum:
            return None
        return dict(Urun.DURUM_SECENEKLERI).get(obj.onceki_durum, obj.onceki_durum)


    def get_yeni_durum_label(self, obj):
        return dict(Urun.DURUM_SECENEKLERI).get(obj.yeni_durum, obj.yeni_durum)

    def get_yapan_username(self, obj):
        return obj.yapan.username if obj.yapan else None
