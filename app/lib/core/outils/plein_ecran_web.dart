// Role du fichier : plein ecran sur le web, par l API Fullscreen du navigateur.
// La touche Echap sort du plein ecran : le navigateur s en charge, l application suit l etat reel.

import 'dart:js_interop';

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _Element? get documentElement;
  external _Element? get fullscreenElement;
  external JSPromise<JSAny?> exitFullscreen();
}

extension type _Element._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> requestFullscreen();
}

/// Entre et sort du plein ecran dans le navigateur.
class PleinEcran {
  const PleinEcran._();

  /// Vrai quand la page est en plein ecran, selon le navigateur lui meme.
  static bool get actif => _document.fullscreenElement != null;

  /// Demande le plein ecran au navigateur.
  static Future<void> entrer() async {
    final _Element? racine = _document.documentElement;
    if (racine == null) {
      return;
    }
    await racine.requestFullscreen().toDart;
  }

  /// Quitte le plein ecran.
  static Future<void> quitter() async {
    if (_document.fullscreenElement == null) {
      return;
    }
    await _document.exitFullscreen().toDart;
  }

  /// Entre ou sort, selon l etat reel de la page.
  static Future<void> basculer() => actif ? quitter() : entrer();
}
