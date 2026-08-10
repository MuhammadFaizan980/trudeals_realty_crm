import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import '../cubits/auth_cubit.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TruDealsColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.px, vertical: 32.px),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.px),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/icon/logo.png',
                        width: 72.px,
                        height: 72.px,
                      ),
                    ),
                    SizedBox(height: 20.px),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 27.px,
                          color: TruDealsColors.ink,
                        ),
                        children: const [
                          TextSpan(text: 'TruDeals'),
                          TextSpan(text: ' Realty', style: TextStyle(color: TruDealsColors.sageDeep)),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.px),
                    Text(
                      'BROKERAGE CRM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.px,
                        letterSpacing: 0.14.px,
                        color: TruDealsColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 40.px),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        return _emailRegex.hasMatch(v.trim()) ? null : 'Enter a valid email address';
                      },
                    ),
                    SizedBox(height: 16.px),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                    ),
                    SizedBox(height: 24.px),
                    BlocConsumer<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state is AuthError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                        }
                      },
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  if (!_formKey.currentState!.validate()) return;
                                  context.read<AuthCubit>().login(
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                      );
                                },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.px),
                            backgroundColor: TruDealsColors.sageDeep,
                            foregroundColor: Colors.white,
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text('Login', style: TextStyle(fontSize: 16.px)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
