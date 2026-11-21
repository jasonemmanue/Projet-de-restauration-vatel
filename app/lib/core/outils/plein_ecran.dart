// Role du fichier : point d entree commun du plein ecran.
// Sur Android et iPhone, mode immersif. Sur le web, API Fullscreen du navigateur.
// La sortie se fait par le meme bouton, ou par Echap sur le web.

export 'plein_ecran_appareil.dart' if (dart.library.js_interop) 'plein_ecran_web.dart';
