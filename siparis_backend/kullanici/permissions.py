from rest_framework.permissions import BasePermission, IsAuthenticated
class IsYoneticiUser(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user and 
            request.user.is_authenticated and 
            getattr(request.user, 'role', None) == 'yonetici'
        )