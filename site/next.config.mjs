// Role du fichier : reglages Next.js du site public de Cantine Vatel.
// Export statique : le site part sur un hebergement de fichiers, sans serveur Node.

/** @type {import('next').NextConfig} */
const config = {
  output: 'export',
  reactStrictMode: true,
  poweredByHeader: false,
  images: {
    // L export statique ne peut pas optimiser les images a la volee.
    unoptimized: true,
    dangerouslyAllowSVG: true,
    contentDispositionType: 'attachment',
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
  },
};

export default config;
