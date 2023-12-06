import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showPasswordResetEmailSentDialog(BuildContext context) async {
  await showGenericDialog(
    context: context,
    title: 'Password Reset Email Sent',
    content: 'Please check your email to reset your password.',
    optionsBuilder: () => {
      'Ok': null,
    },
  );
}
