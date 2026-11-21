// Role du fichier : savoir si Firebase a demarre, pour que F7 n essaie pas de s y brancher pour rien.
// Sans Firebase, l application tourne normalement : seules les notifications poussees manquent.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vrai quand Firebase a demarre. Remplace au demarrage de l application.
final Provider<bool> firebasePretProvider = Provider<bool>((Ref ref) => false);
