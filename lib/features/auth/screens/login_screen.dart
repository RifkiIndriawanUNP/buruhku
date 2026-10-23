import 'package:flutter/material.dart';
import '../../../app/services.dart'; 
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/box.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '081234567890');
  bool _loading = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Services.auth.requestOtp(_phone.text.trim());
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(phone: _phone.text.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.handshake_outlined, size: 72, color: AppTheme.primary),
              const SizedBox(height: 20),
              Text(
                'Selamat datang di Buruhku',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Masuk dengan nomor HP Anda',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              Form(
                key: _form,
                child: TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  validator: phoneValidator,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kirim OTP'),
              ),
              const SizedBox(height: 16),
              AppBox(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade100),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode demo: gunakan nomor apa saja, lalu kode OTP 123456.',
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}