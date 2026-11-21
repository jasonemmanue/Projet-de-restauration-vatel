// Role du fichier : reglages Next.js du site public de Cantine Vatel.

/** @type {import('next').NextConfig} */
const config = {
  reactStrictMode: true,
  poweredByHeader: false,
  images: {
    // Les logos de la marque et des boutiques sont des SVG locaux, ecrits dans ce depot.
    // Next refuse les SVG par defaut : on les autorise, enfermes dans un bac a sable.
    dangerouslyAllowSVG: true,
    contentDispositionType: 'attachment',
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
  },
};

export default config;
