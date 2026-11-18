import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/server/api_service.dart';
import 'package:frontend/controller/resell_controller.dart';

class SellerRegistrationPage extends StatefulWidget {
  const SellerRegistrationPage({super.key});

  @override
  State<SellerRegistrationPage> createState() => _SellerRegistrationPageState();
}

class _SellerRegistrationPageState extends State<SellerRegistrationPage> {
  static const Color pink = Color(0xFFE85D9E);
  static const Color background = Color(0xFFFFF5F8);

  final _formKey = GlobalKey<FormState>();
  final ResellController _resellController = ResellController();

  final _fullName = TextEditingController();
  final _nationalId = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  bool _submitted = false;
  String _statusMessage =
      'Your identity verification request has been submitted successfully.';

  @override
  void initState() {
    super.initState();
    _prefillProfile();
  }

  Future<void> _prefillProfile() async {
    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        if ((profile['full_name'] ?? '').toString().isNotEmpty) {
          _fullName.text = profile['full_name'].toString();
        }
        if ((profile['phone'] ?? '').toString().isNotEmpty) {
          _phone.text = profile['phone'].toString();
        }
        if ((profile['email'] ?? '').toString().isNotEmpty) {
          _email.text = profile['email'].toString();
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _fullName.dispose();
    _nationalId.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: pink),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: pink, width: 2),
      ),
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
      decoration: _decoration(label, icon, hint: hint),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: pink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _resellController.registerSeller(
        fullName: _fullName.text,
        nationalId: _nationalId.text,
        acceptedTerms: _acceptedTerms,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitted = true;
        if (response['message'] != null) {
          _statusMessage = response['message'].toString();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _registrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Seller Identity Verification',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verify your identity to start selling concert tickets.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          _section('Identity Information', Icons.verified_user_outlined, [
            _field(
              label: 'Full Name (as on National ID)',
              icon: Icons.badge_outlined,
              controller: _fullName,
            ),
            const SizedBox(height: 14),
            _field(
              label: 'National ID (13 digits)',
              hint: 'Enter 13-digit Thai National ID',
              icon: Icons.credit_card_outlined,
              controller: _nationalId,
              keyboardType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.length != 13) {
                  return 'Please enter a 13-digit National ID';
                }
                if (!ResellController.isValidThaiNationalId(trimmed)) {
                  return 'Invalid National ID number';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _field(
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              controller: _phone,
              keyboardType: TextInputType.phone,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || !RegExp(r'^0\d{9}$').hasMatch(value)) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _field(
              label: 'Email',
              icon: Icons.email_outlined,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null ||
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ]),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CheckboxListTile(
              value: _acceptedTerms,
              activeColor: pink,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I agree to the seller identity verification terms and conditions',
                style: TextStyle(fontSize: 13),
              ),
              onChanged: (value) {
                setState(() {
                  _acceptedTerms = value ?? false;
                });
              },
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Submit Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successPage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.check_circle, color: Colors.green, size: 90),
          const SizedBox(height: 20),
          const Text(
            'Verification Submitted!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Seller Registration'),
        backgroundColor: pink,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _submitted ? _successPage() : _registrationForm(),
            ),
          ),
        ),
      ),
    );
  }
}