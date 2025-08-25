import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siparis_takip/sayfalar/oturum/giris.dart';
import 'package:siparis_takip/services/api_service.dart';

class KayitOl extends StatefulWidget {
  const KayitOl({super.key});

  @override
  State<KayitOl> createState() => _KayitOlState();
}

class _KayitOlState extends State<KayitOl> {
  final _formKey = GlobalKey<FormState>();
  final _kullaniciAdi = TextEditingController();
  final _sifre = TextEditingController();
  final _sifreTekrar = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _password2Focus = FocusNode();

  bool _obscure = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _kullaniciAdi.dispose();
    _sifre.dispose();
    _sifreTekrar.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _password2Focus.dispose();
    super.dispose();
  }

  // Basit parola gücü (0..1)
  double _passwordStrength(String p) {
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += .25;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += .25;
    if (RegExp(r'[0-9]').hasMatch(p)) s += .25;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s += .25;
    return s.clamp(0, 1);
  }

  String _strengthLabel(double v) {
    if (v < .25) return "Zayıf";
    if (v < .5) return "Orta";
    if (v < .75) return "İyi";
    return "Güçlü";
  }

  Color _strengthColor(double v) {
    if (v < .25) return Colors.redAccent;
    if (v < .5) return Colors.orange;
    if (v < .75) return Colors.amber[700]!;
    return Colors.green;
  }

  Future<void> _kaydol() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final sonuc = await ApiService.registerUser(
        username: _kullaniciAdi.text.trim(),
        password: _sifre.text,
      );

      if (!mounted) return;
      if (sonuc['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${sonuc['message'] ?? 'Kayıt başarılı'}")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GirisSayfasi()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${sonuc['message'] ?? 'Kayıt başarısız'}")),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Sunucuya ulaşılamadı")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg1 = Colors.indigo.shade50;
    final bg2 = Colors.indigo.shade100;
    final primary = Colors.indigo.shade600;

    final pwStrength = _passwordStrength(_sifre.text);

    return Scaffold(
      backgroundColor: bg1,
      // Klavye açıldığında Scaffold zıplamasın
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
                final bottom = MediaQuery.of(context).viewInsets.bottom;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    22,
                    34,
                    22,
                    bottom > 0 ? bottom + 16 : 34,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 34,
                    ),
                    child: IntrinsicHeight(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Card(
                            elevation: 8,
                            color: Colors.white,
                            shadowColor: Colors.black.withOpacity(.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                26,
                                22,
                                22,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 4),
                                    // Avatar
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
                                          Icons.person_add_alt_1,
                                          size: 44,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "Kayıt Ol",
                                        style: GoogleFonts.quicksand(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.indigo.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Kullanıcı adı
                                    _buildField(
                                      label: "Kullanıcı Adı",
                                      hint: "kullanici_adiniz",
                                      controller: _kullaniciAdi,
                                      focusNode: _usernameFocus,
                                      textInputAction: TextInputAction.next,
                                      icon: Icons.person_outline,
                                      validator: (v) {
                                        final t = v?.trim() ?? "";
                                        if (t.isEmpty)
                                          return "Kullanıcı adı zorunlu";
                                        if (t.length < 3)
                                          return "En az 3 karakter olmalı";
                                        return null;
                                      },
                                      onFieldSubmitted:
                                          (_) => _passwordFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 14),

                                    // Şifre
                                    _buildField(
                                      label: "Şifre",
                                      hint: "••••••••",
                                      controller: _sifre,
                                      focusNode: _passwordFocus,
                                      isPassword: true,
                                      obscure: _obscure,
                                      onToggleObscure:
                                          () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                      icon: Icons.lock_outline,
                                      textInputAction: TextInputAction.next,
                                      validator: (v) {
                                        final p = v ?? "";
                                        if (p.isEmpty) return "Şifre zorunlu";
                                        if (p.length < 8)
                                          return "En az 8 karakter olmalı";
                                        return null;
                                      },
                                      onChanged:
                                          (_) => setState(
                                            () {},
                                          ), // güç barını güncelle
                                      onFieldSubmitted:
                                          (_) => _password2Focus.requestFocus(),
                                    ),

                                    const SizedBox(height: 10),
                                    _PasswordStrengthBar(
                                      strength: pwStrength,
                                      label: _strengthLabel(pwStrength),
                                      color: _strengthColor(pwStrength),
                                      background: Colors.grey.shade200,
                                    ),
                                    const SizedBox(height: 14),

                                    // Şifre (tekrar)
                                    _buildField(
                                      label: "Şifre (Tekrar)",
                                      hint: "••••••••",
                                      controller: _sifreTekrar,
                                      focusNode: _password2Focus,
                                      isPassword: true,
                                      obscure: _obscure2,
                                      onToggleObscure:
                                          () => setState(
                                            () => _obscure2 = !_obscure2,
                                          ),
                                      icon: Icons.lock_reset_outlined,
                                      textInputAction: TextInputAction.done,
                                      validator: (v) {
                                        if ((v ?? "").isEmpty)
                                          return "Tekrar şifre zorunlu";
                                        if (v != _sifre.text)
                                          return "Parolalar uyuşmuyor";
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _kaydol(),
                                    ),

                                    const SizedBox(height: 22),

                                    // Kayıt Ol
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _loading ? null : _kaydol,
                                        icon:
                                            _loading
                                                ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : const Icon(
                                                  Icons.app_registration,
                                                ),
                                        label: Text(
                                          _loading
                                              ? "Kaydediliyor..."
                                              : "Kayıt Ol",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Girişe dön
                                    TextButton.icon(
                                      onPressed:
                                          _loading
                                              ? null
                                              : () => Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          const GirisSayfasi(),
                                                ),
                                              ),
                                      icon: const Icon(Icons.login),
                                      label: const Text(
                                        "Zaten hesabın var mı? Giriş Yap",
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: primary,
                                      ),
                                    ),

                                    const Spacer(), // kartın altını dengeler
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

  // Reusable input
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    FocusNode? focusNode,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            onFieldSubmitted: onFieldSubmitted,
            onChanged: onChanged,
            obscureText: isPassword ? obscure : false,
            validator: validator,
            textInputAction: textInputAction,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.circle,
                color: Colors.transparent,
                size: 0,
              ), // spacing sabit kalsın
              // yukarıdaki hile yerine doğrudan Icon(icon) da kullanabilirsin:
              // prefixIcon: Icon(icon, color: Colors.indigo),
              hintText: hint,
              filled: true,
              fillColor: Colors.indigo.shade50,
              border: InputBorder.none,
              suffixIcon:
                  isPassword
                      ? IconButton(
                        onPressed: onToggleObscure,
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                      )
                      : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final double strength; // 0..1
  final String label;
  final Color color;
  final Color background;

  const _PasswordStrengthBar({
    required this.strength,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: strength == 0 ? null : strength, // 0 iken indeterminate
          minHeight: 6,
          color: color,
          backgroundColor: background,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
