import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/concert.jpg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),

          Container(color: Colors.black.withOpacity(0.55)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 340,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        fontFamily: 'Redaction',
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          // Username
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: const TextStyle(
                                color: Colors.black54,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Fullname
                          TextFormField(
                            controller: _fullnameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: const TextStyle(
                                color: Colors.black54,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(
                                color: Colors.black54,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Phone Number
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              labelStyle: const TextStyle(
                                color: Colors.black54,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: const Icon(Icons.phone_outlined),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(
                                color: Colors.black54,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: const TextStyle(
                                color: Colors.black54,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: const Icon(Icons.lock_reset),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          // error message
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ปุ่ม Register
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                String username = _usernameController.text
                                    .trim();
                                String fullname = _fullnameController.text
                                    .trim();
                                String email = _emailController.text.trim();
                                String phone = _phoneController.text.trim();
                                String password = _passwordController.text
                                    .trim();
                                String confirmPassword =
                                    _confirmPasswordController.text.trim();

                                if (username.isEmpty ||
                                    fullname.isEmpty ||
                                    email.isEmpty ||
                                    phone.isEmpty ||
                                    password.isEmpty ||
                                    confirmPassword.isEmpty) {
                                  setState(() {
                                    _errorMessage =
                                        'Please fill in all fields';
                                  });
                                  return;
                                }

                                // เปลี่ยนด้านหลังได้ ตอนนี้มันใสส่ตัวอักษรหลังจาก . ได้แค่ 2-4 ตัว
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(email)) {
                                  setState(() {
                                    _errorMessage = 'Invalid email format';
                                  });
                                  return;
                                }

                                if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                                  setState(() {
                                    _errorMessage =
                                        'Phone number must be 10 digits';
                                  });
                                  return;
                                }

                                if (password != confirmPassword) {
                                  setState(() {
                                    _errorMessage = 'Passwords do not match';
                                  });
                                  return;
                                }

                                setState(() {
                                  _errorMessage = null;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Registration successful'),
                                    backgroundColor: Colors.pinkAccent,
                                  ),
                                );

                                Navigator.pop(context);

                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Redaction',
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text.rich(
                        TextSpan(
                          text: "Already have an account? ",
                          style: const TextStyle(color: Colors.white70),
                          children: const [
                            TextSpan(
                              text: 'Login here',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
