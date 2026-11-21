// Role du fichier : la coquille de toutes les pages du site public.

import type { Metadata, Viewport } from 'next';

import './globals.css';

export const metadata: Metadata = {
  title: 'Cantine Vatel',
  description:
    'Réserve ton repas, choisis ton créneau, montre ton QR au comptoir. La cantine de Vatel, sans file d attente.',
  icons: { icon: '/marque/favicon-48.png', apple: '/marque/apple-touch-icon-180.png' },
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#f4f6fb' },
    { media: '(prefers-color-scheme: dark)', color: '#0b1220' },
  ],
};

export default function Coquille({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body className="min-h-screen bg-fond font-sans text-texte antialiased">{children}</body>
    </html>
  );
}
