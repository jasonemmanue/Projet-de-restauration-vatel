// Role du fichier : le badge de boutique, dessine a taille fixe.
// Le logo vit dans une boite carree de 26 px en ajustement par contenu, et le texte est sur deux
// lignes de taille fixe : le badge ne se deforme sur aucun ecran.

import Image from 'next/image';

type Props = {
  /** Lien de la boutique ou de l application web. */
  href: string;
  /** Petite ligne du haut, par exemple « Disponible sur ». */
  surtitre: string;
  /** Grande ligne du bas, par exemple « Google Play ». */
  titre: string;
  /** Fichier du logo dans /public. */
  logo: string;
  /** Texte alternatif du logo. */
  alt: string;
};

export function BadgeBoutique({ href, surtitre, titre, logo, alt }: Props) {
  return (
    <a
      href={href}
      className="inline-flex h-[58px] w-[196px] flex-none items-center gap-3 rounded-petit bg-contraste px-4 text-sur-contraste transition-transform duration-200 ease-douce hover:scale-[1.02] focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent"
    >
      <span className="flex h-[26px] w-[26px] flex-none items-center justify-center">
        <Image src={logo} alt={alt} width={26} height={26} className="h-[26px] w-auto" />
      </span>
      <span className="flex min-w-0 flex-col leading-tight">
        <span className="text-[10px] uppercase tracking-wide opacity-80">{surtitre}</span>
        <span className="text-[15px] font-bold">{titre}</span>
      </span>
    </a>
  );
}
