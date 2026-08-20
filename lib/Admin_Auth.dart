import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin_Dashboard.dart';
import 'Api/App_Api.dart';

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
    final Size size = MediaQuery.of(context).size;
    final bool isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: LuxuryTheme.primaryDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2C23),
              Color(0xFF0A1E18),
              Color(0xFF05110E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Ambient Glow Spheres
            Positioned(top: -100, left: -80, child: _buildGlowSphere(300, LuxuryTheme.primaryAccent)),
            Positioned(bottom: -120, right: -80, child: _buildGlowSphere(350, LuxuryTheme.secondaryAccent)),

            // Centered Glassmorphic Container
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      width: isDesktop ? 820 : 420,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: LuxuryTheme.primaryAccent.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(isDesktop ? 36 : 24),
                      child: Form(
                        key: _formKey,
                        child: isDesktop
                            ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 6, child: _buildFormSection()),
                            const SizedBox(width: 36),
                            Container(
                              width: 1,
                              height: 380,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    LuxuryTheme.primaryAccent.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 36),
                            Expanded(flex: 5, child: _buildSidePanelSection()),
                          ],
                        )
                            : Column(
                          children: [
                            _buildFormSection(),
                            const SizedBox(height: 28),
                            _buildSidePanelSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowSphere(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 100,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    String title;
    String subtitle;
    String buttonText;

    if (_authMode == AuthMode.signIn) {
      title = "Welcome Back";
      subtitle = "Sign in to access your admin dashboard";
      buttonText = "Sign In";
    } else {
      if (_resetStep == ResetStep.enterEmail) {
        title = "Reset Password";
        subtitle = "Enter your email to receive a verification OTP";
        buttonText = "Send OTP";
      } else if (_resetStep == ResetStep.enterOtp) {
        title = "Verify OTP";
        subtitle = "Enter the 6-digit code sent to your inbox";
        buttonText = "Verify OTP";
      } else {
        title = "New Password";
        subtitle = "Set up your new password to regain access";
        buttonText = "Update Password";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Logo
        Center(
          child: SizedBox(
            height: 70,
            child: Image.asset(
              "assets/photos/bindu.png",
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.apartment,
                color: LuxuryTheme.primaryAccent,
                size: 50,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 2,
          width: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [LuxuryTheme.primaryAccent, LuxuryTheme.secondaryAccent],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Dynamic Form Fields based on state
        if (_authMode == AuthMode.signIn || _resetStep == ResetStep.enterEmail) ...[
          _buildTextField(
            controller: _emailController,
            label: "Email Address",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return "Please enter your email";
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return "Invalid email format";
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],

        if (_authMode == AuthMode.signIn) ...[
          _buildTextField(
            controller: _passwordController,
            label: "Password",
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
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _switchAuthMode(AuthMode.resetPassword),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Forgot Password?",
                style: GoogleFonts.plusJakartaSans(
                  color: LuxuryTheme.primaryAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],

        if (_authMode == AuthMode.resetPassword && _resetStep == ResetStep.enterOtp) ...[
          _buildTextField(
            controller: _otpController,
            label: "Enter 6-Digit OTP",
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.trim().length != 6) return "Enter valid 6-digit OTP";
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],

        if (_authMode == AuthMode.resetPassword && _resetStep == ResetStep.newPassword) ...[
          _buildTextField(
            controller: _newPasswordController,
            label: "New Password",
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
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: "Retype New Password",
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
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 20),

        // Action Button
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [LuxuryTheme.primaryAccent, LuxuryTheme.secondaryAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: LuxuryTheme.primaryAccent.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleFormSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: LuxuryTheme.primaryDark,
              ),
            )
                : Text(
              buttonText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: LuxuryTheme.primaryDark,
              ),
            ),
          ),
        ),

        if (_authMode == AuthMode.resetPassword) ...[
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
                onTap: () => _switchAuthMode(AuthMode.signIn),
                child: Text("Back to Sign In", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: LuxuryTheme.primaryAccent, fontWeight: FontWeight.bold))),
          ),
        ]
      ],
    );
  }

  Widget _buildSidePanelSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              const Icon(Icons.format_quote, color: LuxuryTheme.primaryAccent, size: 28),
              const SizedBox(height: 8),
              Text(
                "“ The spaces have been waiting in silence. One thoughtful detail, and suddenly the whole room remembers how to feel like home. ”",
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: LuxuryTheme.primaryAccent, size: 16),
            const SizedBox(width: 8),
            Text("Protected & Authenticated Portal", style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.6), fontSize: 11, letterSpacing: 0.3)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          cursorColor: LuxuryTheme.primaryAccent,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            prefixIcon: Icon(icon, color: LuxuryTheme.primaryAccent.withOpacity(0.7), size: 18),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: onToggleVisibility,
            )
                : null,
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: LuxuryTheme.primaryAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}