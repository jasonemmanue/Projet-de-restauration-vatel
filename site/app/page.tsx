// Role du fichier : la page d accueil du site public de Cantine Vatel.
// Elle montre la marque, ce que fait l application, et le bon bouton de telechargement
// selon l appareil du visiteur. Les adresses des boutiques sont des variables d environnement.

import Image from 'next/image';

import { BoutonsConnexion } from '@/components/BoutonsConnexion';
import { BoutonsTelechargement } from '@/components/BoutonsTelechargement';
import { CodeQr } from '@/components/CodeQr';

const lienPlay = process.env.NEXT_PUBLIC_LIEN_PLAY ?? 'https://play.google.com/store/apps/details?id=com.vatel.cantine';
const lienAppStore = process.env.NEXT_PUBLIC_LIEN_APP_STORE ?? 'https://apps.apple.com/app/cantine-vatel';
const lienApplication = process.env.NEXT_PUBLIC_LIEN_APPLICATION ?? 'https://app.cantine-vatel.ci';

const atouts = [
  {
    titre: 'Plus de file d attente',
    detail: 'Tu réserves avant l heure limite, tu choisis ton créneau, et tu passes au comptoir avec ton QR.',
  },
  {
    titre: 'Le menu de la semaine',
    detail: 'Publié le jeudi pour toute la semaine suivante, avec les allergènes et les régimes de chaque plat.',
  },
  {
    titre: 'Un porte-monnaie à toi',
    detail:
      'Tout le monde recharge son compte par Mobile Money. Un parent peut recharger celui de son enfant, et un proche peut payer par un lien.',
  },
  {
    titre: 'Moins de gaspillage',
    detail: 'La cuisine sait ce qu elle doit préparer, et les portions restantes partent à prix réduit en fin de service.',
  },
];

export default function Accueil() {
  return (
    <main className="mx-auto flex w-full max-w-contenu flex-col gap-20 px-4 py-14 sm:px-6">
      <section className="flex flex-col items-center gap-10 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex max-w-[560px] flex-col items-center gap-6 text-center lg:items-start lg:text-left">
          <div className="flex items-center gap-3">
            <Image src="/marque/symbole.svg" alt="" width={52} height={52} className="h-[52px] w-[52px]" />
            <div className="flex flex-col leading-tight">
              <span className="text-[20px] font-extrabold tracking-tight">Cantine Vatel</span>
              <span className="text-[10px] uppercase tracking-[0.18em] text-texte-secondaire">
                Commande · Repas · QR
              </span>
            </div>
          </div>

          <h1 className="text-[32px] leading-tight sm:text-[44px]">
            La cantine de Vatel, sans file d attente.
          </h1>
          <p className="max-w-[460px] text-[16px] text-texte-secondaire">
            Réserve ton repas, choisis ton créneau de passage, et montre ton code QR au comptoir. Les parents
            rechargent le compte en Mobile Money, la cuisine sait quoi préparer.
          </p>

          <BoutonsTelechargement lienPlay={lienPlay} lienAppStore={lienAppStore} lienWeb={lienApplication} />
        </div>

        <div className="flex flex-col items-center gap-6 rounded-grand border border-filet bg-surface p-8">
          <h2 className="text-[20px]">Déjà un compte ?</h2>
          <BoutonsConnexion lienApplication={lienApplication} />
          <div className="h-px w-full bg-filet" />
          <CodeQr valeur={lienApplication} cote={132} legende="Ouvrir l application sur ton téléphone" />
        </div>
      </section>

      <section className="grid gap-5 sm:grid-cols-2">
        {atouts.map((atout) => (
          <article key={atout.titre} className="rounded-carte border border-filet bg-surface p-6">
            <h2 className="text-[20px]">{atout.titre}</h2>
            <p className="mt-2 text-[15px] text-texte-secondaire">{atout.detail}</p>
          </article>
        ))}
      </section>

      <footer className="flex flex-col items-center gap-3 border-t border-filet pt-8 text-center text-[13px] text-texte-secondaire">
        <p>Cantine Vatel, Abidjan. Paiements Mobile Money par GeniusPay.</p>
        <p>
          <a href="/legal/conditions" className="underline">
            Conditions d utilisation
          </a>
          {' · '}
          <a href="/legal/confidentialite" className="underline">
            Confidentialité
          </a>
          {' · '}
          <a href="mailto:cantine@vatel.ci" className="underline">
            cantine@vatel.ci
          </a>
        </p>
      </footer>
    </main>
  );
}
