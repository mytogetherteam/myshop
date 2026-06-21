import 'package:flutter/material.dart';
import 'package:my_shop/core/presentation/widgets/keyboard_padding_wrapper.dart';

class GlobalModal {
  /// Displays a generic, globally styled modal dialog.
  /// This layout wraps any [Widget] child passed into it.
  static void show({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: barrierDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return KeyboardPaddingWrapper(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36.0)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28.0, 36.0, 28.0, 28.0),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}