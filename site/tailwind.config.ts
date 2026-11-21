// Role du fichier : la charte de docs/CHARTE.md, traduite en classes Tailwind.
// Les couleurs ne sont ecrites nulle part ailleurs dans le site.

import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        accent: 'var(--accent)',
        'accent-doux': 'var(--accent-doux)',
        'sur-accent': 'var(--sur-accent)',
        fond: 'var(--fond)',
        surface: 'var(--surface)',
        muet: 'var(--muet)',
        filet: 'var(--filet)',
        texte: 'var(--texte)',
        'texte-secondaire': 'var(--texte-secondaire)',
        succes: 'var(--succes)',
        danger: 'var(--danger)',
        alerte: 'var(--alerte)',
        contraste: 'var(--contraste)',
        'sur-contraste': 'var(--sur-contraste)',
      },
      borderRadius: {
        petit: '14px',
        carte: '22px',
        grand: '28px',
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'system-ui', 'sans-serif'],
      },
      maxWidth: {
        contenu: '1200px',
      },
      transitionTimingFunction: {
        douce: 'cubic-bezier(0.22, 1, 0.36, 1)',
      },
    },
  },
  plugins: [],
};

export default config;
