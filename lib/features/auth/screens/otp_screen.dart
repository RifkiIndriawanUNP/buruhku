import 'package:flutter/material.dart';
import '../../../app/env.dart';
import '../../../app/services.dart';
import '../../../core/utils/validators.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController(text: Env.otpDemoCode);
  final _name = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Services.auth.verifyOtp(
        widget.phone,
        _code.text.trim(),
        fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
      );
      if (!mounted) return;
      // Navigate back to root; root will show MainShell
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kode OTP dikirim ke\n${widget.phone}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nama Anda (opsional)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kode OTP 6 digit',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => requiredValidator(v, 'Kode OTP wajib diisi'), 
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verifikasi'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Demo: gunakan OTP ${Env.otpDemoCode}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}