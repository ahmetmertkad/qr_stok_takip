from django.contrib.auth.models import AbstractUser
from django.db import models

ROLE_CHOICES = [
    ('yonetici', 'Yönetici'),
    ('personel', 'Personel'),
    ('depo_gorevlisi', 'Depo Görevlisi'),
]

class CustomUser(AbstractUser):
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='personel')
