import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AdminDashboard.dart';
import 'Api/Auth_Api.dart';

class LuxuryTheme {
  static const Color primaryDark = Color(0xFF0F2C23);
  static const Color primaryAccent = Color(0xFFD4AF37);
  static const Color secondaryAccent = Color(0xFFC5A059);
  static const Color bgCream = Color(0xFFFBF9F5);
}

enum AuthMode { signIn, resetPassword }
enum ResetStep { enterEmail, enterOtp, newPassword }

class AdminAuth extends StatefulWidget {
  const AdminAuth({super.key});

  @override
  State<AdminAuth> createState() => _AdminAuthState();
}

class _AdminAuthState extends State<AdminAuth> {
  final _formKey = GlobalKey<FormState>();

  AuthMode _authMode = AuthMode.signIn;
  ResetStep _resetStep = ResetStep.enterEmail;
  bool _isLoading = false;

  // Password Visibility States
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchAuthMode(AuthMode mode) {
    setState(() {
      _authMode = mode;
      _resetStep = ResetStep.enterEmail;
      _formKey.currentState?.reset();
    });
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : LuxuryTheme.primaryAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: LuxuryTheme.primaryDark,
      ),
    );
  }

  // =================================================
  // SAVE DATA TO SHARED PREFERENCES
  // =================================================
  Future<void> _handleLoginResponse(Map<String, dynamic> responseData) async {
    if (responseData['status'] == true) {
      final prefs = await SharedPreferences.getInstance();

      // Extract user object from PHP response
      final user = responseData['user'];

      if (user != null) {
        // Save login session and user details
        await prefs.setBool('is_logged_in', true);
        await prefs.setInt('user_id', user['id'] ?? 0);
        await prefs.setString('user_name', user['name'] ?? '');
        await prefs.setString('user_email', user['email'] ?? '');
      }
    }
  }

  Future<void> _handleFormSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // =================================================
      // SIGN IN
      // =================================================
      if (_authMode == AuthMode.signIn) {
        final data = await Api.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (data['status'] == true) {
          // Save login details to SharedPreferences
          await _handleLoginResponse(data);

          _showSnackBar("Signed in successfully!");

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          _showSnackBar(
            data['message'] ?? "Invalid email or password",
            isError: true,
          );
        }
        return;
      }

      // =================================================
      // FORGOT PASSWORD - STEP 1: SEND OTP
      // =================================================
      if (_resetStep == ResetStep.enterEmail) {
        final data = await Api.sendOtp(
          email: _emailController.text.trim(),
        );

        if (data['status'] == true) {
          _showSnackBar("OTP sent to your email!");

          if (!mounted) return;

          setState(() {
            _resetStep = ResetStep.enterOtp;
          });
        } else {
          _showSnackBar(
            data['message'] ?? "Failed to send OTP",
            isError: true,
          );
        }
        return;
      }

      // =================================================
      // FORGOT PASSWORD - STEP 2: VERIFY OTP
      // =================================================
      if (_resetStep == ResetStep.enterOtp) {
        final data = await Api.verifyOtp(
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
        );

        if (data['status'] == true) {
          _showSnackBar("OTP verified! Enter your new password.");

          if (!mounted) return;

          setState(() {
            _resetStep = ResetStep.newPassword;
          });
        } else {
          _showSnackBar(
            data['message'] ?? "Invalid OTP",
            isError: true,
          );
        }
        return;
      }

      // =================================================
      // FORGOT PASSWORD - STEP 3: RESET PASSWORD
      // =================================================
      if (_resetStep == ResetStep.newPassword) {
        final data = await Api.resetPassword(
          email: _emailController.text.trim(),
          password: _newPasswordController.text,
        );

        if (data['status'] == true) {
          _showSnackBar("Password reset successfully!");

          if (!mounted) return;

          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _otpController.clear();

          _switchAuthMode(AuthMode.signIn);
        } else {
          _showSnackBar(
            data['message'] ?? "Failed to update password",
            isError: true,
          );
        }
        return;
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        "Connection error. Please check your internet/API.",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxuryTheme.primaryDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 750,
            constraints: const BoxConstraints(minHeight: 460),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Form(
                key: _formKey,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Custom Curved Sidebar Navigation Panel
                      Expanded(
                        flex: 4,
                        child: _buildLeftSidebar(),
                      ),

                      // Right Main Form Panel
                      Expanded(
                        flex: 6,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Circular Profile Icon Header
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: LuxuryTheme.primaryDark,
                                  boxShadow: [
                                    BoxShadow(
                                      color: LuxuryTheme.primaryDark.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: LuxuryTheme.primaryAccent,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _authMode == AuthMode.signIn
                                    ? "Sign In"
                                    : (_resetStep == ResetStep.enterEmail
                                    ? "RESET PASSWORD"
                                    : (_resetStep == ResetStep.enterOtp
                                    ? "VERIFY OTP"
                                    : "NEW PASSWORD")),
                                style: GoogleFonts.cinzel(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: LuxuryTheme.primaryDark,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 25),

                              // Dynamic Form Fields
                              if (_authMode == AuthMode.signIn || _resetStep == ResetStep.enterEmail) ...[
                                _buildUnderlineTextField(
                                  controller: _emailController,
                                  hintText: "Email",
                                  icon: Icons.person_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return "Please enter your email";
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                      return "Invalid email format";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              if (_authMode == AuthMode.signIn) ...[
                                _buildUnderlineTextField(
                                  controller: _passwordController,
                                  hintText: "Password",
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  onToggleVisibility: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return "Please enter your password";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () => _switchAuthMode(AuthMode.resetPassword),
                                    child: Text(
                                      "Forgot Password?",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: LuxuryTheme.primaryDark.withOpacity(0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildSubmitButton("Sign IN"),
                                ),
                              ],

                              if (_authMode == AuthMode.resetPassword && _resetStep == ResetStep.enterOtp) ...[
                                _buildUnderlineTextField(
                                  controller: _otpController,
                                  hintText: "6-Digit OTP",
                                  icon: Icons.pin_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (val) {
                                    if (val == null || val.trim().length != 6) return "Enter valid 6-digit OTP";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildSubmitButton("VERIFY OTP"),
                                ),
                              ],

                              if (_authMode == AuthMode.resetPassword && _resetStep == ResetStep.newPassword) ...[
                                _buildUnderlineTextField(
                                  controller: _newPasswordController,
                                  hintText: "New Password",
                                  icon: Icons.lock_reset_outlined,
                                  isPassword: true,
                                  obscureText: _obscureNewPassword,
                                  onToggleVisibility: () {
                                    setState(() {
                                      _obscureNewPassword = !_obscureNewPassword;
                                    });
                                  },
                                  validator: (val) {
                                    if (val == null || val.length < 6) return "Password must be at least 6 characters";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildUnderlineTextField(
                                  controller: _confirmPasswordController,
                                  hintText: "Retype Password",
                                  icon: Icons.check_circle_outline,
                                  isPassword: true,
                                  obscureText: _obscureConfirmPassword,
                                  onToggleVisibility: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                  validator: (val) {
                                    if (val != _newPasswordController.text) return "Passwords do not match";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildSubmitButton("UPDATE"),
                                ),
                              ],

                              if (_authMode == AuthMode.resetPassword && _resetStep == ResetStep.enterEmail) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildSubmitButton("SEND OTP"),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Stack(
      children: [
        // Diagonal Layered Geometric Background Colors
        Container(color: LuxuryTheme.primaryDark),
        Positioned.fill(
          child: CustomPaint(
            painter: ImageBackgroundPainter(),
          ),
        ),
        // Active Curved Tab Indicator
        Positioned(
          top: 140,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: CustomPaint(
              size: const Size(120, 50),
              painter: TabCurvedPainter(),
              child: Container(
                width: 120,
                height: 50,
                alignment: Alignment.center,
                padding: const EdgeInsets.only(right: 15),
                child: Text(
                  _authMode == AuthMode.signIn ? "Sign IN" : "RESET",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: LuxuryTheme.primaryDark,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Tab Action Items
        Positioned(
          top: 140,
          left: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: GestureDetector(
                  onTap: () => _switchAuthMode(AuthMode.signIn),
                  child: Text("SIGN IN", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white.withOpacity(_authMode == AuthMode.signIn ? 1.0 : 0.6), fontSize: 13, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(color: LuxuryTheme.primaryDark, fontSize: 14),
      cursorColor: LuxuryTheme.primaryDark,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade600,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        )
            : null,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: LuxuryTheme.primaryDark, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String text) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleFormSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: LuxuryTheme.primaryDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 3,
      ),
      child: _isLoading
          ? const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: LuxuryTheme.primaryAccent,
        ),
      )
          : Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// Custom Painter for Left-side Geometric Polygon Layers using Luxury Theme Colors
class ImageBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = LuxuryTheme.primaryDark.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.75, 0)
      ..lineTo(0, size.height * 0.85)
      ..close();

    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = LuxuryTheme.secondaryAccent.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for the Smooth White Curved Tab Indicator on the Left
class TabCurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(25, 0);
    path.cubicTo(10, 0, 0, 10, 0, 25);
    path.cubicTo(0, 40, 10, 50, 25, 50);
    path.lineTo(size.width, 50);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}