// Role du fichier : le retour haptique leger de l application.
// Jamais sur le web, ou il n existe pas : la regle est tenue ici, pas dans les ecrans.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Les retours haptiques prevus par la charte.
class Haptique {
  const Haptique._();

  /// Changement d onglet, selection : le plus leger.
  static void leger() {
    if (kIsWeb) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
  }

  /// Reservation prise, scan accepte.
  static void succes() {
    if (kIsWeb) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Scan refuse, action impossible.
  static void refus() {
    if (kIsWeb) {
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
  }
}
