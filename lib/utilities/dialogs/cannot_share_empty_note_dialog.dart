import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyNoteDialog(BuildContext context) async {
  await showGenericDialog(
      context: context,
      title: 'Cannot Share',
      content: 'Cannot share an empty note.',
      optionsBuilder: () => {
            'Ok': null,
          });
}
