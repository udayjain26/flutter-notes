import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_events.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Column(children: [
        const Text('An email has been sent to your email address.'),
        const Text('Havn\'t received an email?'),
        TextButton(
            onPressed: () {
              context
                  .read()<AuthBloc>()
                  .add(const AuthEventSendEmailVerification());
            },
            child: const Text('Send Email Verification')),
        TextButton(
            onPressed: () {
              context.read()<AuthBloc>().add(
                    const AuthEventLogout(),
                  );
            },
            child: const Text('Restart')),
      ]),
    );
  }
}
