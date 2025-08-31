import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'forgotPassword.dart';
import 'signUp.dart';
import '../screens/VerifyEmail.dart';

import 'package:paw_ui/screens/HomePage.dart' as home;
import '../screens/HomePageAdmin.dart' as admin;


/// EDIT THIS: any email in this set is treated as an admin and
/// will bypass email verification at login.
const Set<String> kAdminEmails = {
  'admin@pawpal.app',
  'ainaaahadi@gmail.com',
  'syarifhsyed@gmail.com',
  'adirantsh@gmail.com',
  // 'your.other.admin@email.com',
};

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _auth = FirebaseAuth.instance;
  String _email = "";
  String _password = "";
  bool _loading = false;
  String _error = "";

Future<void> _handleLogin() async {
  setState(() {
    _loading = true;
    _error = "";
  });

  try {
    final cred = await _auth.signInWithEmailAndPassword(
      email: _email.trim(),
      password: _password,
    );
    final user = cred.user;

    if (user == null) {
      setState(() => _error = "Login failed");
      return;
    }

    // -------- ADMIN RULE FIRST (navigate here directly) --------
    final normalized = _email.trim().toLowerCase();
    final isAdmin = kAdminEmails.contains(normalized);

    if (isAdmin) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const admin.HomePageAdmin()),
        (route) => false,
      );
      return;
    }

    // -------- NORMAL USER FLOW --------
    if (!user.emailVerified) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmail()),
      );
      // User returns and taps Login again after verifying
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const home.HomePageView(
          isAuthorizing: false, // required param in your constructor
        ),
      ),
      (route) => false,
    );
  } on FirebaseAuthException catch (e) {
    setState(() => _error = e.message ?? "Login failed");
  } catch (e) {
    setState(() => _error = "Login failed: $e");
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}


  void _openForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return ForgotPassword(
          connecting: false,
          errorMessage: "",
          infoMessage: "",
          onSendReset: (email) => Navigator.pop(ctx),
          onChangePassword: (email, newPwd) => Navigator.pop(ctx),
          onBackToLogin: () => Navigator.pop(ctx),
        );
      },
    );
  }

  void _openSignUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SignUp(
          connecting: false,
          errorMessage: "",
          onSubmit: (username, email, password) async {
            try {
              final cred = await _auth.createUserWithEmailAndPassword(
                email: email.trim(),
                password: password,
              );
              await cred.user?.sendEmailVerification();

              if (!mounted) return;
              Navigator.pop(ctx); // close SignUp sheet

              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerifyEmail()),
              );
            } on FirebaseAuthException catch (e) {
              if (mounted) setState(() => _error = e.message ?? "Sign up failed");
            } catch (e) {
              if (mounted) setState(() => _error = "Sign up failed: $e");
            }
          },
          onBackToLogin: () => Navigator.pop(ctx),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red,
              child: Text(_error, style: const TextStyle(color: Colors.white)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Image.asset("assets/logo.png", height: 100),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email"),
                  onChanged: (v) => _email = v.trim(),
                ),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  onChanged: (v) => _password = v,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openForgotPasswordSheet,
                    child: const Text("Forgot password?"),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          child: const Text("Login"),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: _openSignUpSheet,
                      child: const Text("Sign up"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
