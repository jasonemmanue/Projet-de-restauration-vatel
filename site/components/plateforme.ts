// Role du fichier : reconnaitre l appareil du visiteur, pour ne proposer que ce qui lui sert.
// Android, y compris l application web sur Android, ne voit que Google.
// iPhone, iPad et ordinateur voient Google et Apple.

export type Appareil = 'android' | 'ios' | 'ordinateur';

/** Rend l appareil du visiteur, lu dans le navigateur. */
export function lireAppareil(): Appareil {
  if (typeof navigator === 'undefined') {
    return 'ordinateur';
  }
  const agent = navigator.userAgent;
  if (/android/i.test(agent)) {
    return 'android';
  }
  // iPadOS se presente comme un Mac : seul l ecran tactile le trahit.
  const estIpad = /Macintosh/.test(agent) && navigator.maxTouchPoints > 1;
  if (/iPad|iPhone|iPod/.test(agent) || estIpad) {
    return 'ios';
  }
  return 'ordinateur';
}

/** Rend les fournisseurs de connexion a proposer sur cet appareil. */
export function fournisseurs(appareil: Appareil): Array<'google' | 'apple'> {
  return appareil === 'android' ? ['google'] : ['google', 'apple'];
}
