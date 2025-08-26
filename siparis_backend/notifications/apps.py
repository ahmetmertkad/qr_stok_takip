# notifications/apps.py
from django.apps import AppConfig

class NotificationsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'notifications'

    def ready(self):
        # Django her açıldığında Firebase Admin’i başlat
        import firebase_admin
        from firebase_admin import credentials
        from django.conf import settings

        if not firebase_admin._apps:
            cred = credentials.Certificate(str(settings.FIREBASE_CREDENTIALS_FILE))
            firebase_admin.initialize_app(cred)
