import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:thuc_tap/services/auth_service.dart';
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
                  const SizedBox(height: 20),

                  // Back button and title row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // App Logo with red pin
                  Container(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        // Blue paper (back)
                        Positioned(
                          right: 10,
                          top: 15,
                          child: Container(
                            width: 70,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4FC3F7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        // Yellow paper (front)
                        Positioned(
                          left: 15,
                          top: 5,
                          child: Container(
                            width: 70,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFF200)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 15),
                                  Container(
                                    height: 2,
                                    width: 35,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 2,
                                    width: 30,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 2,
                                    width: 25,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 2,
                                    width: 35,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Red pin/thumbtack
                        Positioned(
                          right: 25,
                          top: 0,
                          child: Container(
                            width: 20,
                            height: 25,
                            child: Stack(
                              children: [
                                // Pin head
                                Positioned(
                                  top: 0,
                                  left: 5,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                // Pin needle
                                Positioned(
                                  top: 8,
                                  left: 9,
                                  child: Container(
                                    width: 2,
                                    height: 15,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Trang đăng ký',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Full Name Input
                  _buildInputField(
                    controller: _nameController,
                    hintText: 'Nhập họ và tên',
                    prefixIcon: Icons.person_outline,
                  ),

                  const SizedBox(height: 16),

                  // Email Input
                  _buildInputField(
                    controller: _emailController,
                    hintText: 'Nhập email của bạn',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Password Input
                  _buildInputField(
                    controller: _passwordController,
                    hintText: 'Nhập mật khẩu',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
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
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password Input
                  _buildInputField(
                    controller: _confirmPasswordController,
                    hintText: 'Nhập lại mật khẩu',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async{
                        final name = _nameController.text.trim();
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        final confirmPassword = _confirmPasswordController.text;

                        if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                          );
                          return;
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email không hợp lệ')),
                          );
                          return;
                        }

                        if (password != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mật khẩu không khớp')),
                          );
                          return;
                        }
                        if (password.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mật khẩu phải có ít nhất 8 ký tự')),
                          );
                          return;
                        }

                        final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$');
                        if (!passwordRegex.hasMatch(password)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mật khẩu phải chứa ít nhất 1 chữ hoa, 1 chữ thường và 1 số'),
                            ),
                          );
                          return;
                        }


                        final success = await AuthService.register(name, email, password);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đăng ký thành công')),
                          );
                          Navigator.pop(context); // Quay về trang đăng nhập
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đăng ký thất bại')),
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
                        'ĐĂNG KÝ',
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
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
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: Colors.grey),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

