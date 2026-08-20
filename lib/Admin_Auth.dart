import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Admin_Dashboard.dart';

// Color Palette Theme
class LuxuryTheme {
  static const Color primaryDark = Color(0xFF0F2C23); // Dark Emerald Green
  static const Color primaryAccent = Color(0xFFD4AF37); // Signature Gold
  static const Color secondaryAccent = Color(0xFFC5A059); // Muted Gold Accent
  static const Color bgCream = Color(0xFFFBF9F5); // Elegant Warm Ivory
  static const Color textMuted = Color(0xFF55605C);
}

enum AuthMode { signIn, signUp, resetPassword }

enum ResetStep { enterEmail, enterOtp, newPassword }

class AdminAuth extends StatefulWidget {
  const AdminAuth({super.key});

  @override
  State<AdminAuth> createState() => _AdminAuthState();
}

class _AdminAuthState extends State<AdminAuth> {
  final _formKey = GlobalKey<FormState>();

  AuthMode _authMode = AuthMode.signUp;
  ResetStep _resetStep = ResetStep.enterEmail;

  bool _agreeTerms = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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

  void _handleFormSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_authMode == AuthMode.resetPassword) {
        if (_resetStep == ResetStep.enterEmail) {
          setState(() {
            _resetStep = ResetStep.enterOtp;
          });
        } else if (_resetStep == ResetStep.enterOtp) {
          setState(() {
            _resetStep = ResetStep.newPassword;
          });
        } else if (_resetStep == ResetStep.newPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Password successfully reset! Please sign in.", style: GoogleFonts.plusJakartaSans()),
              backgroundColor: LuxuryTheme.primaryDark,
            ),
          );
          _switchAuthMode(AuthMode.signIn);
        }
      } else if (_authMode == AuthMode.signUp) {
        if (!_agreeTerms) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please agree to the Terms & Conditions.", style: GoogleFonts.plusJakartaSans()),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account created successfully!", style: GoogleFonts.plusJakartaSans()),
            backgroundColor: LuxuryTheme.primaryDark,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Signed in successfully!", style: GoogleFonts.plusJakartaSans()),
            backgroundColor: LuxuryTheme.primaryDark,
          ),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminDashboard()));
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
            colors: [
              LuxuryTheme.primaryDark,
              Color(0xFF14372E),
              Color(0xFF0A201A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Decorative Spheres
            Positioned(
              top: -60,
              left: -60,
              child: _buildGlowSphere(220, LuxuryTheme.primaryAccent),
            ),
            Positioned(
              bottom: -80,
              right: -50,
              child: _buildGlowSphere(280, LuxuryTheme.secondaryAccent),
            ),

            // Main Centered Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Glassmorphism Main Card with Reduced Dimensions
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: isDesktop ? 780 : 410, // Decreased size
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: LuxuryTheme.primaryAccent.withOpacity(0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 25,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(isDesktop ? 28 : 20), // Tighter interior padding
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
                  ],
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
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 90,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  // Left Side Dynamic Form Section
  Widget _buildFormSection() {
    String title;
    String buttonText;

    switch (_authMode) {
      case AuthMode.signUp:
        title = "Join the\nFuture";
        buttonText = "Sign Up";
        break;
      case AuthMode.signIn:
        title = "Welcome\nBack";
        buttonText = "Sign In";
        break;
      case AuthMode.resetPassword:
        if (_resetStep == ResetStep.enterEmail) {
          title = "Reset\nPassword";
          buttonText = "Verify Email";
        } else if (_resetStep == ResetStep.enterOtp) {
          title = "Verify\nOTP";
          buttonText = "Verify OTP";
        } else {
          title = "New\nPassword";
          buttonText = "Update Password";
        }
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: SizedBox(
              height:75,
              child: Image.asset("assets/photos/bindu.png")),
        ),
        // Title with Google Fonts Cinzel
        Text(title, style: GoogleFonts.cinzel(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.15, letterSpacing: 1.0,)),
        const SizedBox(height: 6),

        // Accent Line
        Container(
          height: 2.5,
          width: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [LuxuryTheme.primaryAccent, LuxuryTheme.secondaryAccent],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Sign Up Fields
        if (_authMode == AuthMode.signUp) ...[
          _buildTextField(
            controller: _nameController,
            label: "Full Name",
            validator: (val) {
              if (val == null || val.trim().isEmpty) return "Please enter your name";
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],

        // Email Field
        if (_authMode != AuthMode.resetPassword || _resetStep == ResetStep.enterEmail) ...[
          _buildTextField(
            controller: _emailController,
            label: "Email Address",
            validator: (val) {
              if (val == null || val.trim().isEmpty) return "Please enter your email";
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                return "Please enter a valid email";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],

        // Password Field
        if (_authMode != AuthMode.resetPassword) ...[
          _buildTextField(
            controller: _passwordController,
            label: "Password",
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) return "Please enter your password";
              if (val.length < 6) return "Password must be at least 6 characters";
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],

        // OTP Field
        if (_authMode == AuthMode.resetPassword && _resetStep == ResetStep.enterOtp) ...[
          _buildTextField(
            controller: _otpController,
            label: "Enter 6-Digit OTP",
            validator: (val) {
              if (val == null || val.trim().length != 6) {
                return "Please enter a valid 6-digit OTP";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],

        // Reset Password New Password Fields
        if (_authMode == AuthMode.resetPassword && _resetStep == ResetStep.newPassword) ...[
          _buildTextField(
            controller: _newPasswordController,
            label: "New Password",
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) return "Please enter new password";
              if (val.length < 6) return "Password must be at least 6 characters";
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _confirmPasswordController,
            label: "Retype New Password",
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) return "Please retype your password";
              if (val != _newPasswordController.text) {
                return "Passwords do not match";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],

        // Options Footer
        if (_authMode == AuthMode.signUp)
          Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: _agreeTerms,
                  activeColor: LuxuryTheme.primaryAccent,
                  checkColor: LuxuryTheme.primaryDark,
                  side: BorderSide(color: Colors.white.withOpacity(0.6)),
                  onChanged: (val) {
                    setState(() {
                      _agreeTerms = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "I agree to the Terms & Conditions",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          )
        else if (_authMode == AuthMode.signIn)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _switchAuthMode(AuthMode.resetPassword),
              child: Text(
                "Forgot Password?",
                style: GoogleFonts.plusJakartaSans(color: LuxuryTheme.primaryAccent, fontSize: 12),
              ),
            ),
          ),

        const SizedBox(height: 18),

        // Action Button
        Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [LuxuryTheme.primaryAccent, LuxuryTheme.secondaryAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: LuxuryTheme.primaryAccent.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleFormSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Text(buttonText, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: LuxuryTheme.primaryDark, letterSpacing: 0.8)),
          ),
        ),
        const SizedBox(height: 14),

        // Mode Switchers
        Center(
          child: GestureDetector(
            onTap: () {
              if (_authMode == AuthMode.signUp) {
                _switchAuthMode(AuthMode.signIn);
              } else {
                _switchAuthMode(AuthMode.signUp);
              }
            },
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70),
                children: [
                  TextSpan(
                    text: _authMode == AuthMode.signUp
                        ? "Already have an account? "
                        : "Don't have an account? ",
                  ),
                  TextSpan(
                    text: _authMode == AuthMode.signUp ? "Sign In" : "Sign Up",
                    style: GoogleFonts.plusJakartaSans(
                      color: LuxuryTheme.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Right Side Information Panel
  Widget _buildSidePanelSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Centered Header Tag with Small Logo
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LuxuryTheme.primaryAccent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _authMode == AuthMode.signUp ? "Welcome back" : "New here?",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _switchAuthMode(
                      _authMode == AuthMode.signUp ? AuthMode.signIn : AuthMode.signUp,
                    );
                  },
                  child: Image.asset(
                    "assets/photos/bindu.png",
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.lock, color: LuxuryTheme.primaryAccent, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Glass Quote Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "“ The spaces have been waiting in silence. One thoughtful detail, and suddenly the whole room remembers how to feel like home. ”",
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Image.asset(
                    "assets/photos/bindu.png",
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Bindu Décor Admin Portal",
                    style: GoogleFonts.plusJakartaSans(
                      color: LuxuryTheme.primaryAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Security Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LuxuryTheme.primaryAccent.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/photos/bindu.png",
                width: 14,
                height: 14,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.security, color: LuxuryTheme.primaryAccent, size: 14),
              ),
              const SizedBox(width: 6),
              Text("Secure & Encrypted", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  // Custom Form TextField Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          cursorColor: LuxuryTheme.primaryAccent,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: LuxuryTheme.primaryAccent, width: 1.8),
            ),
            errorStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFFF6B6B), fontSize: 11),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}