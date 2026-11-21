// Role du fichier : les boutons de connexion du site, mêmes regles que dans l application.
// Android ne voit que Google. iPhone, iPad et ordinateur voient Google et Apple.
// Le logo tient dans une boite carree de 22 px : il ne se deforme jamais.

'use client';

import Image from 'next/image';
import { useEffect, useState } from 'react';

import { fournisseurs, lireAppareil, type Appareil } from './plateforme';

type Props = {
  /** Adresse de l application web, ou la connexion se fait reellement. */
  lienApplication: string;
};

const libelles: Record<'google' | 'apple', { texte: string; logo: string }> = {
  google: { texte: 'Continuer avec Google', logo: '/marque/google-g.svg' },
  apple: { texte: 'Continuer avec Apple', logo: '/marque/apple.svg' },
};

export function BoutonsConnexion({ lienApplication }: Props) {
  const [appareil, setAppareil] = useState<Appareil>('ordinateur');

  useEffect(() => {
    setAppareil(lireAppareil());
  }, []);

  return (
    <div className="flex w-full max-w-[380px] flex-col gap-3">
      {fournisseurs(appareil).map((nom) => (
        <a
          key={nom}
          href={lienApplication}
          className="flex h-[52px] items-center justify-center gap-3 rounded-full border border-filet bg-surface px-5 text-[15px] font-bold text-texte transition-transform duration-200 ease-douce hover:scale-[1.01] focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent"
        >
          <span className="flex h-[22px] w-[22px] flex-none items-center justify-center">
            <Image src={libelles[nom].logo} alt="" width={22} height={22} className="h-[22px] w-auto" />
          </span>
          <span>{libelles[nom].texte}</span>
          <span className="h-[22px] w-[22px] flex-none" aria-hidden="true" />
        </a>
      ))}
      <a
        href={lienApplication}
        className="flex h-[52px] items-center justify-center gap-3 rounded-full border border-filet bg-surface px-5 text-[15px] font-bold text-texte transition-transform duration-200 ease-douce hover:scale-[1.01] focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent"
      >
        <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true" className="flex-none">
          <path
            fill="currentColor"
            d="M3 3h8v8H3V3Zm2 2v4h4V5H5Zm8-2h8v8h-8V3Zm2 2v4h4V5h-4ZM3 13h8v8H3v-8Zm2 2v4h4v-4H5Zm8 0h2v2h-2v-2Zm4-2h4v2h-2v2h2v4h-4v-2h-2v2h-2v-4h4v-2h-2v-2h2v-2Zm2 8h2v-2h-2v2Z"
          />
        </svg>
        <span>Se connecter avec un code QR</span>
        <span className="h-[22px] w-[22px] flex-none" aria-hidden="true" />
      </a>
    </div>
  );
}
