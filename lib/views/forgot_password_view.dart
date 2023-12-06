import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_events.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';
import 'package:mynotes/utilities/dialogs/password_reset_email_sent_dialog.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateForgotPassword) {
          if (state.hasSentEmail) {
            _controller.clear();
            await showPasswordResetEmailSentDialog(context);
          }
          if (state.exception != null) {
            if (!context.mounted) return;
            await showErrorDialog(
              context,
              'Could not process your request. Make sure you are a registered used.',
            );
          }
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Forgot password'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Enter your email address to reset your password.'),
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofocus: true,
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                TextButton(
                    onPressed: () {
                      final email = _controller.text;
                      context.read()<AuthBloc>().add(
                            AuthEventForgotPassword(email: email),
                          );
                    },
                    child: const Text('Reset password')),
                TextButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(const AuthEventLogout());
                    },
                    child: const Text('Back to login page')),
              ],
            ),
          )),
    );
  }
}
