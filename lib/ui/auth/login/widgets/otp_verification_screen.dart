import 'dart:async';
import 'package:blog_app/core/constants.dart';
import 'package:blog_app/routing/routes.dart';
import 'package:blog_app/ui/auth/login/bloc/auth_bloc.dart';
import 'package:blog_app/ui/auth/login/bloc/auth_event.dart';
import 'package:blog_app/ui/auth/login/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _start = 300;
  bool _isResendEnabled = false;
  int remainingAttempts = 3; // This should ideally come from backend via state

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _start = Constants.OTP_EXPIRY_TIME * 60; // To convert in seconds
    _isResendEnabled = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() => _isResendEnabled = true);
        _timer?.cancel();
      } else {
        setState(() => _start--);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Email',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            GoRouter.of(context).pushNamed(Routes.registerUser);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Enter the 6-digit code sent to',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Pinput(
              controller: _otpController,
              length: 6,
              defaultPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: const TextStyle(fontSize: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// 📌 Attempts Info
            Text(
              'You have $remainingAttempts attempts to verify today.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            /// ✅ Verify Button
            ElevatedButton(
              onPressed: (_start > 0 && _otpController.text.length == 6)
                  ? () {
                      context.read<AuthBloc>().add(
                        OtpSubmitted(
                          email: widget.email,
                          password: widget.password,
                          enteredOtp: _otpController.text,
                          name: widget.name,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: (_start > 0 && _otpController.text.length == 6)
                    ? theme.colorScheme.primary
                    : theme.disabledColor.withOpacity(0.5),
                foregroundColor: Colors.white,
                disabledBackgroundColor: theme.disabledColor.withOpacity(0.5),
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Verify'),
            ),
            const SizedBox(height: 12),

            /// ⏳ Timer Info
            Text('Time remaining: ${_formatTime(_start)}'),

            const SizedBox(height: 8),

            /// 🔁 Resend Code Link
            GestureDetector(
              onTap: _isResendEnabled
                  ? () {
                      context.read<AuthBloc>().add(
                        OTPRequested(
                          email: widget.email,
                          password: widget.password,
                          name: widget.email,
                        ),
                      );
                      _startTimer();
                    }
                  : null,
              child: Text(
                'Resend Code',
                style: TextStyle(
                  fontSize: 14,
                  color: _isResendEnabled
                      ? theme.colorScheme.primary
                      : Colors.grey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// 🔴 Bloc Feedback
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthSuccess) {
                  GoRouter.of(context).pushNamed(Routes.home);
                } else if (state is AuthFailure) {
                  return Column(
                    children: [
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Attempts left: ${remainingAttempts - 1}', // you can pass this from AuthFailure state
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
