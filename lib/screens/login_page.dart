import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thuc_tap/screens/home_page.dart';
import 'signup_page.dart';
import 'package:thuc_tap/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberLogin = true;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 100,
                    height: 100,
                    child: Stack(
                      children: [
                        Positioned(
                          right: 0,
                          top: 8,
                          child: Container(
                            width: 65,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          top: 0,
                          child: Container(
                            width: 65,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFF200)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 15),
                                  Container(
                                    height: 2,
                                    width: 30,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    height: 2,
                                    width: 25,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    height: 2,
                                    width: 20,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              width: 50,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF20B2AA),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 15,
                          top: 5,
                          child: Icon(
                            Icons.diamond,
                            color: Color(0xFF20B2AA),
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Notes App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 25),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.black54, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Nhập email của bạn',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.black54, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;

                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập đầy đủ email và mật khẩu')),
                          );
                          return;
                        }

                        final response = await AuthService.login(email, password);

                        if (response != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chào ${response.name}!')),
                          );

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('user_id', response.id);
                          await prefs.setString('token', response.token);
                          await prefs.setString('user_name', response.name);
                          await prefs.setString('user_email', response.email);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sai email hoặc mật khẩu')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'ĐĂNG NHẬP',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()));
                          },
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
