from rest_framework import serializers
from .models import CustomUser

class KayitSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['username', 'password', 'role','is_active']
        extra_kwargs = {
            'password': {'write_only': True}
        }

    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password'],
            is_active=False  # Kayıt olan kullanıcı giriş yapamasın
        )
        return user
    

from rest_framework import serializers
from .models import CustomUser

class RolGuncelleSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['role']  # Sadece role alanı güncellensin

    def update(self, instance,validated_data):
        instance.role = validated_data.get('role', instance.role)
        instance.save()
        return instance

class DurumGuncelle(serializers.ModelSerializer):
      
      class Meta:
          model =CustomUser
          fields=['is_active']
    
      def update(self,instance,validated_data):
          instance.is_active = validated_data.get('is_active', instance.is_active)
          instance.save()
          return instance
          
            
