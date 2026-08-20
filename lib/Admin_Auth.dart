import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isError ? Colors.redAccent : LuxuryTheme.primaryDark,
      ),
    );
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

          _showSnackBar(
            "Signed in successfully!",
          );


          if (!mounted) return;


          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const AdminDashboard(),
            ),
          );

        } else {

          _showSnackBar(
            data['message'] ??
                "Invalid email or password",
            isError: true,
          );
        }

        return;
      }


      // =================================================
      // FORGOT PASSWORD
      // =================================================

      // -------------------------------------------------
      // STEP 1: SEND OTP
      // -------------------------------------------------

      if (_resetStep == ResetStep.enterEmail) {

        final data = await Api.sendOtp(
          email: _emailController.text.trim(),
        );


        if (data['status'] == true) {

          _showSnackBar(
            "OTP sent to your email!",
          );


          if (!mounted) return;


          setState(() {

            _resetStep =
                ResetStep.enterOtp;

          });

        } else {

          _showSnackBar(
            data['message'] ??
                "Failed to send OTP",
            isError: true,
          );
        }

        return;
      }


      // -------------------------------------------------
      // STEP 2: VERIFY OTP
      // -------------------------------------------------

      if (_resetStep == ResetStep.enterOtp) {

        final data = await Api.verifyOtp(
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
        );


        if (data['status'] == true) {

          _showSnackBar(
            "OTP verified! Enter your new password.",
          );


          if (!mounted) return;


          setState(() {

            _resetStep =
                ResetStep.newPassword;

          });

        } else {

          _showSnackBar(
            data['message'] ??
                "Invalid OTP",
            isError: true,
          );
        }

        return;
      }


      // -------------------------------------------------
      // STEP 3: RESET PASSWORD
      // -------------------------------------------------

      if (_resetStep == ResetStep.newPassword) {

        final data = await Api.resetPassword(
          email: _emailController.text.trim(),
          password: _newPasswordController.text,
        );


        if (data['status'] == true) {

          _showSnackBar(
            "Password reset successfully!",
          );


          if (!mounted) return;


          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _otpController.clear();


          _switchAuthMode(
            AuthMode.signIn,
          );

        } else {

          _showSnackBar(
            data['message'] ??
                "Failed to update password",
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
      backgroundColor: LuxuryTheme.bgCream,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [LuxuryTheme.primaryDark, Color(0xFF14372E), Color(0xFF0A201A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -60, left: -60, child: _buildGlowSphere(220, LuxuryTheme.primaryAccent)),
            Positioned(bottom: -80, right: -50, child: _buildGlowSphere(280, LuxuryTheme.secondaryAccent)),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: isDesktop ? 780 : 410,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: LuxuryTheme.primaryAccent.withOpacity(0.3), width: 1.2),
                      ),
                      padding: EdgeInsets.all(isDesktop ? 28 : 20),
                      child: Form(
                        key: _formKey,
                        child: isDesktop
                            ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: _buildFormSection()),
                            const SizedBox(width: 28),
                            Expanded(flex: 5, child: _buildSidePanelSection()),
                          ],
                        )
                            : Column(
                          children: [
                            _buildFormSection(),
                            const SizedBox(height: 20),
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
        color: color.withOpacity(0.15),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 90, spreadRadius: 20),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    String title;
    String buttonText;

    if (_authMode == AuthMode.signIn) {
      title = "Welcome\nBack";
      buttonText = "Sign In";
    } else {
      if (_resetStep == ResetStep.enterEmail) {
        title = "Reset\nPassword";
        buttonText = "Send OTP";
      } else if (_resetStep == ResetStep.enterOtp) {
        title = "Verify\nOTP";
        buttonText = "Verify OTP";
      } else {
        title = "New\nPassword";
        buttonText = "Update Password";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: SizedBox(height: 75, child: Image.asset("assets/photos/bindu.png")),
        ),
        Text(title, style: GoogleFonts.cinzel(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.15)),
        const SizedBox(height: 6),
        Container(
          height: 2.5,
          width: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(colors: [LuxuryTheme.primaryAccent, LuxuryTheme.secondaryAccent]),
          ),
        ),
        const SizedBox(height: 20),

        if (_authMode == AuthMode.signIn || _resetStep == ResetStep.enterEmail) ...[
          _buildTextField(
            controller: _emailController,
            label: "Email Address",
            validator: (val) {
              if (val == null || val.trim().isEmpty) return "Please enter your email";
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return "Invalid email format";
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],

        if (_authMode == AuthMode.signIn) ...[
          _buildTextField(
            controller: _passwordController,
            label: "Password",
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) return "Please enter your password";
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _switchAuthMode(AuthMode.resetPassword),
              child: Text("Forgot Password?", style: GoogleFonts.plusJakartaSans(color: LuxuryTheme.primaryAccent, fontSize: 12)),
            ),
          ),
        ],

        if (_authMode == AuthMode.resetPassword && _resetStep == ResetStep.enterOtp) ...[
          _buildTextField(
            controller: _otpController,
            label: "Enter 6-Digit OTP",
            validator: (val) {
              if (val == null || val.trim().length != 6) return "Enter valid 6-digit OTP";
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],

        if (_authMode == AuthMode.resetPassword && _resetStep == ResetStep.newPassword) ...[
          _buildTextField(
            controller: _newPasswordController,
            label: "New Password",
            isPassword: true,
            validator: (val) {
              if (val == null || val.length < 6) return "Password must be at least 6 characters";
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _confirmPasswordController,
            label: "Retype New Password",
            isPassword: true,
            validator: (val) {
              if (val != _newPasswordController.text) return "Passwords do not match";
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [LuxuryTheme.primaryAccent, LuxuryTheme.secondaryAccent]),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleFormSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: LuxuryTheme.primaryDark))
                : Text(buttonText, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: LuxuryTheme.primaryDark)),
          ),
        ),

        if (_authMode == AuthMode.resetPassword) ...[
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => _switchAuthMode(AuthMode.signIn),
              child: Text("Back to Sign In", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: LuxuryTheme.primaryAccent, fontWeight: FontWeight.bold)),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildSidePanelSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Text(
            "“ The spaces have been waiting in silence. One thoughtful detail, and suddenly the whole room remembers how to feel like home. ”",
            style: GoogleFonts.cormorantGaramond(color: Colors.white.withOpacity(0.85), fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security, color: LuxuryTheme.primaryAccent, size: 14),
            const SizedBox(width: 6),
            Text("Secure & Encrypted", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          cursorColor: LuxuryTheme.primaryAccent,
          validator: validator,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: LuxuryTheme.primaryAccent, width: 1.8)),
            errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF6B6B))),
            focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1.8)),
          ),
        ),
      ],
    );
  }
}