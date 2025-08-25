# views.py
from django.db import transaction
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Prefetch, Count  # Count burada

from .permissions import AnyRole
from django.contrib.auth import get_user_model
User = get_user_model()

from .models import Urun, UrunDurumGecmisi
from .serializers import UrunSerializer, UrunDurumGecmisiSerializer


class UrunViewSet(viewsets.ModelViewSet):
    queryset = Urun.objects.all().order_by('-id')
    serializer_class = UrunSerializer
    permission_classes = [permissions.IsAuthenticated]

    # /urunler/filtrele/?ad=...&model_no=...
    @action(detail=False, methods=['get'], url_path='filtrele',
            permission_classes=[AnyRole("yonetici", "depo_gorevlisi", "personel")])
    def filtrele(self, request):
        ad = request.query_params.get('ad')
        model_no = request.query_params.get('model_no')

        queryset = Urun.objects.all()
        if ad:
            queryset = queryset.filter(ad__icontains=ad)
        if model_no:
            queryset = queryset.filter(model_no__icontains=model_no)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    # 1) Model no'ya göre durum sayıları
    @action(detail=False, methods=['get'], url_path='urun-durum',
            permission_classes=[AnyRole("yonetici", "personel")])  # type: ignore
    def urun_durum(self, request):
        model_no = request.query_params.get('model_no')
        if not model_no:
            return Response({"error": "model_no gerekli"}, status=status.HTTP_400_BAD_REQUEST)

        durum_sayilari = (
            Urun.objects
            .filter(model_no=model_no)
            .values("durum")
            .annotate(sayi=Count("id"))  # ✅ Count
        )
        sonuc = {item["durum"]: item["sayi"] for item in durum_sayilari}

        return Response({"model_no": model_no, "durumlar": sonuc}, status=status.HTTP_200_OK)

    # 2) Stok koduna göre durum sayıları
    @action(detail=False, methods=['get'], url_path='stok-durum',
            permission_classes=[AnyRole("yonetici", "personel")])  # type: ignore
    def stok_durum(self, request):
        stok_kodu = request.query_params.get('stok_kodu')
        if not stok_kodu:
            return Response({"error": "stok_kodu gerekli"}, status=status.HTTP_400_BAD_REQUEST)

        durum_sayilari = (
            Urun.objects
            .filter(stok_kodu=stok_kodu)
            .values("durum")
            .annotate(sayi=Count("id"))  # ✅ Count
        )
        sonuc = {item["durum"]: item["sayi"] for item in durum_sayilari}

        return Response({"stok_kodu": stok_kodu, "durumlar": sonuc}, status=status.HTTP_200_OK)

    # /urunler/qr-bul/?stok_kodu=...
    @action(detail=False, methods=['get'], url_path='qr-bul',
            permission_classes=[AnyRole("yonetici", "depo_gorevlisi")])
    def qr_bul(self, request):
        stok_kodu = request.query_params.get('stok_kodu')
        if not stok_kodu:
            return Response({"error": "stok_kodu gerekli"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            urun = Urun.objects.get(stok_kodu=stok_kodu)
        except Urun.DoesNotExist:
            return Response({"error": "Ürün bulunamadı"}, status=status.HTTP_404_NOT_FOUND)

        return Response(UrunSerializer(urun).data, status=status.HTTP_200_OK)

    # /urunler/modeller/?ad=...
    @action(detail=False, methods=['get'], url_path='modeller',
            permission_classes=[AnyRole("yonetici", "depo_gorevlisi", "personel")])
    def modelleri_getir(self, request):
        ad = request.query_params.get('ad')
        if not ad:
            return Response({"error": "Ad parametresi gerekli."}, status=status.HTTP_400_BAD_REQUEST)

        modeller = Urun.objects.filter(ad=ad).values_list('model_no', flat=True).distinct()
        return Response({"modeller": list(modeller)}, status=status.HTTP_200_OK)

    # /urunler/filtre-secimleri/
    @action(detail=False, methods=['get'], url_path='filtre-secimleri',
            permission_classes=[AnyRole("yonetici", "depo_gorevlisi", "personel")])
    def filtre_secimleri(self, request):
        adlar = Urun.objects.values_list('ad', flat=True).distinct()
        return Response({"adlar": list(adlar)}, status=status.HTTP_200_OK)

    # /urunler/adlar/
    @action(detail=False, methods=['get'], url_path='adlar',
            permission_classes=[AnyRole("yonetici", "depo_gorevlisi", "personel")])
    def adlari_getir(self, request):
        adlar = Urun.objects.values_list('ad', flat=True).distinct()
        return Response({"adlar": list(adlar)}, status=status.HTTP_200_OK)

    # /urunler/{pk}/detayli-bilgi/
    @action(detail=True, methods=["get"], url_path="detayli-bilgi",
            permission_classes=[AnyRole("yonetici", "personel")])
    def detayli_bilgi(self, request, pk=None):
        urun = self.get_object()
        durumlar = UrunDurumGecmisi.objects.filter(urun=urun).order_by("-tarih")
        return Response({
            "urun": UrunSerializer(urun).data,
            "durum_gecmisi": UrunDurumGecmisiSerializer(durumlar, many=True).data
        }, status=status.HTTP_200_OK)

    # (Eğer ayrı bir endpoint istiyorsan, adı farklı olsun)
    @action(detail=False, methods=['get'], url_path='urun-durum-model',
            permission_classes=[AnyRole("yonetici", "personel")])  # type: ignore
    def urun_durum_model(self, request):  # ✅ adı değiştirildi
        model_no = request.query_params.get('model_no')
        if not model_no:
            return Response({"error": "model_no gerekli"}, status=status.HTTP_400_BAD_REQUEST)

        durum_sayilari = (
            Urun.objects
            .filter(model_no=model_no)
            .values("durum")
            .annotate(sayi=Count("id"))  # ✅ Count
        )
        sonuc = {item["durum"]: item["sayi"] for item in durum_sayilari}

        return Response({"model_no": model_no, "durumlar": sonuc}, status=status.HTTP_200_OK)

    # /urunler/{pk}/durum-degistir/
    @action(detail=True, methods=['post'], url_path='durum-degistir',
            permission_classes=[AnyRole("yonetici", "depo_gorevlisi", "personel")])
    def durum_degistir(self, request, pk=None):
        urun = self.get_object()
        yeni_durum = request.data.get('yeni_durum')
        aciklama = request.data.get('aciklama', '')

        if not yeni_durum:
            return Response({"error": "Yeni durum gerekli"}, status=status.HTTP_400_BAD_REQUEST)
        if yeni_durum not in dict(Urun.DURUM_SECENEKLERI).keys():
            return Response({"error": "Geçersiz durum"}, status=status.HTTP_400_BAD_REQUEST)

        onceki_durum = urun.durum
        if onceki_durum == yeni_durum:
            return Response({"detail": "Durum zaten bu değer."}, status=status.HTTP_200_OK)

        with transaction.atomic():
            urun.durum = yeni_durum
            urun.save(update_fields=['durum'])

            UrunDurumGecmisi.objects.create(
                urun=urun,
                onceki_durum=onceki_durum,
                yeni_durum=yeni_durum,
                aciklama=aciklama,
                yapan=request.user if request.user.is_authenticated else None,
            )

        serializer = self.get_serializer(urun)
        return Response(serializer.data, status=status.HTTP_200_OK)

    # Detaylı liste (ürün + geçmiş), duruma göre filtre
    @action(detail=False, methods=['get'], url_path='detayli-liste')
    def detayli_liste(self, request):
        durum = request.query_params.get('durum')
        durum_list_raw = request.query_params.get('durum_list')
        limit = request.query_params.get('limit')

        allowed = set(dict(Urun.DURUM_SECENEKLERI).keys())
        qs = Urun.objects.all().order_by('-id')

        if durum:
            if durum not in allowed:
                return Response({"error": f"Geçersiz durum: {durum}"}, status=status.HTTP_400_BAD_REQUEST)
            qs = qs.filter(durum=durum)

        if durum_list_raw:
            lst = [d.strip() for d in durum_list_raw.split(',') if d.strip()]
            invalid = [d for d in lst if d not in allowed]
            if invalid:
                return Response({"error": f"Geçersiz durum(lar): {', '.join(invalid)}"},
                                status=status.HTTP_400_BAD_REQUEST)
            qs = qs.filter(durum__in=lst)

        if limit:
            try:
                qs = qs[:int(limit)]
            except ValueError:
                pass

        qs = qs.prefetch_related(
            Prefetch('durum_gecmisi', queryset=UrunDurumGecmisi.objects.order_by('-tarih'))
        )

        sonuc = []
        for urun in qs:
            durumlar = list(urun.durum_gecmisi.all())
            sonuc.append({
                "urun": UrunSerializer(urun).data,
                "durum_gecmisi": UrunDurumGecmisiSerializer(durumlar, many=True).data
            })

        return Response(sonuc, status=status.HTTP_200_OK)


class UrunDurumGecmisiViewSet(viewsets.ModelViewSet):
    queryset = UrunDurumGecmisi.objects.all().order_by('-tarih')
    serializer_class = UrunDurumGecmisiSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(yapan=self.request.user if self.request.user.is_authenticated else None)

    # ✅ KULLANICI ADLARI
    @action(detail=False, methods=['get'], url_path='kullanici-adlari',
            permission_classes=[permissions.IsAuthenticated])
    def kullanici_adlari(self, request):
        usernames = list(
            User.objects.order_by('username')
            .values_list('username', flat=True)
        )
        return Response(usernames, status=200)

    # ✅ KULLANICIYA GÖRE AKTİVİTELER (username)
    @action(detail=False, methods=['get'],
            url_path=r'kullanici/(?P<username>[^/]+)',
            permission_classes=[permissions.IsAuthenticated])
    def kullanici_aktiviteleri(self, request, username=None):
        user = User.objects.filter(username__iexact=username).only('id').first()
        if user is None:
            return Response({"detail": "Kullanıcı bulunamadı."}, status=404)

        qs = (UrunDurumGecmisi.objects
              .filter(yapan_id=user.id)
              .select_related('urun', 'yapan')
              .order_by('-tarih'))
        ser = self.get_serializer(qs, many=True)
        return Response(ser.data, status=200)

