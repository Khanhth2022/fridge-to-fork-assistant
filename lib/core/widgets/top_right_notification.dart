import 'dart:async';

import 'package:flutter/material.dart';

class TopRightNotification {
  TopRightNotification._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final OverlayState overlayState = Overlay.of(context, rootOverlay: true);

    _dismissTimer?.cancel();
    _activeEntry?.remove();

    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        final MediaQueryData media = MediaQuery.of(overlayContext);
        final double maxWidth = media.size.width < 480 ? media.size.width - 24 : 360;
        final double safeMaxWidth = maxWidth.clamp(220, 360).toDouble();

        return Positioned(
          top: media.padding.top + 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: safeMaxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(overlayContext).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      blurRadius: 14,
                      offset: Offset(0, 6),
                      color: Color(0x33000000),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(overlayContext).colorScheme.onInverseSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _activeEntry = entry;
    overlayState.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_activeEntry == entry) {
        entry.remove();
        _activeEntry = null;
      }
    });
  }
}

void showTopRightNotification(BuildContext context, String message) {
  TopRightNotification.show(context, message);
}
