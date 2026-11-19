import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/network/odoo_api_client.dart";
import "../home/home_screen.dart";

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;

  String _normalizeSaPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r"[^\d]"), "");
    if (digits.startsWith("966")) return "+\$digits";
    if (digits.startsWith("05")) return "+966\${digits.substring(1)}";
    if (digits.startsWith("5")) return "+966\$digits";
    return "+\$digits";
  }

  Future<void> _sendOtp() async {
    final phone = _normalizeSaPhone(_phoneController.text.trim());
    if (phone.length < 13) {
      _showSnack("يرجى إدخال رقم جوال سعودي صحيح");
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(odooApiProvider).requestOtp(phone);
      setState(() => _otpSent = true);
      _showSnack("تم إرسال رمز التحقق إلى \$phone");
    } catch (e) {
      _showSnack("تعذر إرسال رمز التحقق: \$e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _normalizeSaPhone(_phoneController.text.trim());
    final code = _otpController.text.trim();
    if (code.length < 4) {
      _showSnack("يرجى إدخال رمز التحقق");
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(odooApiProvider).verifyOtp(phone: phone, code: code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _showSnack("رمز التحقق غير صحيح");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل الدخول"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "أهلاً بك في مياه Meyah",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "أدخل رقم جوالك لتصلك رسالة التحقق (OTP)",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              enabled: !_otpSent,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: "رقم الجوال (مثال: 05XXXXXXXX)",
                prefixText: "+966 ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: "رمز التحقق (OTP)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A438A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _otpSent ? "تأكيد الدخول" : "إرسال رمز التحقق",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            if (_otpSent)
              TextButton(
                onPressed: _loading ? null : () => setState(() => _otpSent = false),
                child: const Text("تغيير رقم الجوال"),
              ),
          ],
        ),
      ),
    );
  }
}
