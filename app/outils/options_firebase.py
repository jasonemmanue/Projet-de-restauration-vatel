# Role du fichier : fabriquer app/firebase.defines a partir des fichiers de configuration Firebase.
# Ces valeurs ne sont jamais versionnees : le depot est public.
# Lancer depuis app/ : python outils/options_firebase.py

import json
import pathlib
import re

RACINE = pathlib.Path(__file__).resolve().parents[1]
ANDROID = RACINE / 'android' / 'app' / 'google-services.json'
IOS = RACINE / 'ios' / 'Runner' / 'GoogleService-Info.plist'
CIBLE = RACINE / 'firebase.defines'


def lire_plist(chemin: pathlib.Path, cle: str) -> str:
    """Rend la valeur d une cle d un fichier plist, ou une chaine vide."""
    if not chemin.exists():
        return ''
    texte = chemin.read_text(encoding='utf-8')
    trouve = re.search(r'<key>%s</key>\s*<string>([^<]*)</string>' % re.escape(cle), texte)
    return trouve.group(1) if trouve else ''


def main() -> None:
    """Ecrit le fichier de valeurs attendu par --dart-define-from-file."""
    if not ANDROID.exists():
        raise SystemExit(
            f'{ANDROID} manque. Lancer d abord :\n'
            '  firebase apps:sdkconfig ANDROID <app id> --project vatel-project '
            '--out android/app/google-services.json'
        )
    donnees = json.loads(ANDROID.read_text(encoding='utf-8'))
    client = donnees['client'][0]
    projet = donnees['project_info']

    valeurs = {
        'FIREBASE_PROJET': projet['project_id'],
        'FIREBASE_EXPEDITEUR': projet['project_number'],
        'FIREBASE_STOCKAGE': projet.get('storage_bucket', ''),
        'FIREBASE_CLE_ANDROID': client['api_key'][0]['current_key'],
        'FIREBASE_APP_ANDROID': client['client_info']['mobilesdk_app_id'],
        'FIREBASE_CLE_IOS': lire_plist(IOS, 'API_KEY'),
        'FIREBASE_APP_IOS': lire_plist(IOS, 'GOOGLE_APP_ID'),
        'FIREBASE_BUNDLE_IOS': lire_plist(IOS, 'BUNDLE_ID'),
        # Les valeurs web n existent dans aucun fichier local : elles viennent de
        # firebase apps:sdkconfig WEB, a recopier ici une fois pour toutes.
        'FIREBASE_CLE_WEB': '',
        'FIREBASE_APP_WEB': '',
        'FIREBASE_DOMAINE_AUTH': f"{projet['project_id']}.firebaseapp.com",
        'FIREBASE_MESURE_WEB': '',
    }

    if CIBLE.exists():
        # On garde les valeurs web deja renseignees a la main.
        ancien = json.loads(CIBLE.read_text(encoding='utf-8'))
        for cle in ('FIREBASE_CLE_WEB', 'FIREBASE_APP_WEB', 'FIREBASE_MESURE_WEB'):
            if ancien.get(cle):
                valeurs[cle] = ancien[cle]

    CIBLE.write_text(json.dumps(valeurs, indent=2) + '\n', encoding='utf-8')
    print(f'ecrit {CIBLE.name} ({len(valeurs)} valeurs)')


if __name__ == '__main__':
    main()
