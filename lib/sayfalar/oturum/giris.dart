// lib/sayfalar/oturum/giris.dart
import 'package:flutter/material.dart';
import 'package:siparis_takip/sayfalar/oturum/anasayfa.dart';
import 'package:siparis_takip/sayfalar/oturum/kayit.dart';
import 'package:siparis_takip/services/api_service.dart';
import 'package:siparis_takip/services/notification_service.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  bool _isLoading = false;
  String? _hataMesaji;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _hataMesaji = null;
    });

    Map<String, dynamic>? result;

    // 1) SADECE GİRİŞ (ayrı try/catch)
    try {
      result = await ApiService.loginUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _hataMesaji = "❌ Sunucuya bağlanılamadı (giriş).";
          _isLoading = false;
        });
      }
      return;
    }

    // 2) GİRİŞ BAŞARILI MI?
    if (result['success'] == true && result['access'] != null) {
      final username =
          (result['username'] as String?) ?? _usernameController.text.trim();
      final role = (result['role'] as String?) ?? 'personel';

      // 3) FCM’i AYRI TRY/CATCH — Hata olsa bile navigasyonu engelleme
      try {
        await NotificationService.I.initAfterLogin(context: context);
      } catch (e) {
        debugPrint('initAfterLogin hata: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bildirim kurulamadı (devam ediliyor).'),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnaSayfa(kullaniciAdi: username, role: role),
        ),
      );
    } else {
      if (mounted) {
        setState(() {
          _hataMesaji =
              (result?['message'] as String?) ??
              "Geçersiz kullanıcı adı veya şifre.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg1 = Colors.indigo.shade50;
    final bg2 = Colors.indigo.shade100;
    final primary = Colors.indigo.shade600;

    return Scaffold(
      backgroundColor: bg1,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Arka plan gradyanı
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bg1, bg2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Scroll + dinamik bottom padding
            LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    32,
                    24,
                    (bottomInset > 0 ? bottomInset + 16 : 32),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Card(
                            elevation: 8,
                            color: Colors.white,
                            shadowColor: Colors.black.withOpacity(.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.indigo.shade100,
                                        ),
                                        child: const Icon(
                                          Icons.lock_open,
                                          size: 44,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "Hoş Geldiniz",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "Hesabınıza giriş yapın",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Kullanıcı adı
                                    _buildField(
                                      controller: _usernameController,
                                      hintText: "Kullanıcı adı",
                                      icon: Icons.person,
                                      primary: primary,
                                      fill: bg1,
                                      textInputAction: TextInputAction.next,
                                      validator:
                                          (v) =>
                                              (v == null || v.trim().isEmpty)
                                                  ? "Kullanıcı adı gerekli"
                                                  : null,
                                    ),
                                    const SizedBox(height: 14),

                                    // Şifre
                                    _buildField(
                                      controller: _passwordController,
                                      hintText: "Şifre",
                                      icon: Icons.lock,
                                      primary: primary,
                                      fill: bg1,
                                      isPassword: true,
                                      obscure: _obscure,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _login(),
                                      onToggleObscure:
                                          () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                      validator:
                                          (v) =>
                                              (v == null || v.isEmpty)
                                                  ? "Şifre gerekli"
                                                  : null,
                                    ),

                                    if (_hataMesaji != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _hataMesaji!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 22),

                                    // Giriş
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                      onPressed: _isLoading ? null : _login,
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : const Text(
                                                "Giriş Yap",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Kayıt
                                    TextButton(
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => const KayitOl(),
                                                ),
                                              ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: primary,
                                      ),
                                      child: const Text(
                                        "Hesabınız yok mu? Kayıt Ol",
                                      ),
                                    ),

                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Re-usable input
  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color primary,
    required Color fill,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: isPassword ? obscure : false,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: primary),
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}
