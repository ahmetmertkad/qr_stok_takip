# permissions.py
from rest_framework.permissions import BasePermission, SAFE_METHODS

class IsRole(BasePermission):
    """
    request.user.role alanına göre rol tabanlı kontrol.
    """
    allowed_roles: tuple[str, ...] = ()
    message = "Bu işlem için yetkiniz yok."

    def has_permission(self, request, view):
        u = getattr(request, "user", None)
        # superuser her şeye izinli olsun istiyorsan bir satır ekleyebilirsin:
        if getattr(u, "is_superuser", False):
            return True
        return bool(u and u.is_authenticated and getattr(u, "role", None) in self.allowed_roles)

class IsYonetici(IsRole):
    allowed_roles = ("yonetici",)

class IsDepoGorevlisi(IsRole):
    allowed_roles = ("depo_gorevlisi",)

class IsPersonel(IsRole):
    allowed_roles = ("personel",)

def AnyRole(*roles):
    """
    Örn: permission_classes=[IsAuthenticated, AnyRole('yonetici','personel')]
    """
    class _AnyRole(IsRole):
        allowed_roles = roles
    return _AnyRole


class ReadOnlyAnyRole(BasePermission):
    """
    Sadece GET/HEAD/OPTIONS serbest; yazma yok.
    """
    def has_permission(self, request, view):
        return request.method in SAFE_METHODS
