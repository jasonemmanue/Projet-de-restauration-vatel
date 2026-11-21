// Role du fichier : proposer le bon telechargement selon l appareil du visiteur.
// Android voit Google Play et l application web. iPhone et iPad voient l App Store et
// l application web. L ordinateur voit les deux boutiques, l application web, et un code QR
// pour ouvrir l application sur le telephone.

'use client';

import { useEffect, useState } from 'react';

import { BadgeBoutique } from './BadgeBoutique';
import { CodeQr } from './CodeQr';
import { lireAppareil, type Appareil } from './plateforme';

type Props = {
  /** Lien de la fiche Google Play. */
  lienPlay: string;
  /** Lien de la fiche App Store. */
  lienAppStore: string;
  /** Adresse de l application web. */
  lienWeb: string;
};

export function BoutonsTelechargement({ lienPlay, lienAppStore, lienWeb }: Props) {
  // Le premier rendu est celui du serveur : on part de l ordinateur, puis on ajuste.
  const [appareil, setAppareil] = useState<Appareil>('ordinateur');

  useEffect(() => {
    setAppareil(lireAppareil());
  }, []);

  const montrerPlay = appareil === 'android' || appareil === 'ordinateur';
  const montrerAppStore = appareil === 'ios' || appareil === 'ordinateur';

  return (
    <div className="flex flex-col items-center gap-6 sm:items-start">
      <div className="flex flex-wrap justify-center gap-3 sm:justify-start">
        {montrerPlay ? (
          <BadgeBoutique
            href={lienPlay}
            surtitre="Disponible sur"
            titre="Google Play"
            logo="/marque/play.svg"
            alt="Google Play"
          />
        ) : null}
        {montrerAppStore ? (
          <BadgeBoutique
            href={lienAppStore}
            surtitre="Télécharger dans"
            titre="l'App Store"
            logo="/marque/apple.svg"
            alt="App Store"
          />
        ) : null}
        <BadgeBoutique
          href={lienWeb}
          surtitre="Ouvrir sur"
          titre="Web / PC"
          logo="/marque/symbole.svg"
          alt="Cantine Vatel sur le web"
        />
      </div>

      {appareil === 'ordinateur' ? (
        <div className="flex items-center gap-4 rounded-carte border border-filet bg-surface p-4">
          <CodeQr valeur={lienWeb} cote={120} />
          <p className="max-w-[220px] text-[14px] text-texte-secondaire">
            Scanne ce code avec ton téléphone pour ouvrir Cantine Vatel sans taper l&apos;adresse.
          </p>
        </div>
      ) : null}
    </div>
  );
}
