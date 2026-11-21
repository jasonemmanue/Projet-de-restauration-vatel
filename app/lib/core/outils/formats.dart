// Role du fichier : mettre en forme les montants et les dates, partout pareil.
// Les montants sont des entiers XOF : jamais de virgule, jamais de flottant.

/// Rend un montant en francs CFA, par exemple « 1 500 F ».
String formaterXof(int montant) {
  final String chiffres = montant.abs().toString();
  final StringBuffer sortie = StringBuffer();
  for (int index = 0; index < chiffres.length; index++) {
    if (index > 0 && (chiffres.length - index) % 3 == 0) {
      // Espace insécable : le montant ne se coupe jamais en fin de ligne.
      sortie.write(' ');
    }
    sortie.write(chiffres[index]);
  }
  final String signe = montant < 0 ? '-' : '';
  return '$signe$sortie F';
}

/// Rend une heure courte, par exemple « 11:00 ».
String formaterHeure(DateTime instant) =>
    '${instant.hour.toString().padLeft(2, '0')}:${instant.minute.toString().padLeft(2, '0')}';

/// Vrai quand les deux dates tombent le même jour.
bool memeJour(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
