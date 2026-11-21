// Role du fichier : le code QR, noir sur fond blanc dans les deux modes, comme le ticket.
// Il est dessine dans le navigateur : aucun service exterieur ne voit l adresse.

'use client';

import { useEffect, useState } from 'react';
import QRCode from 'qrcode';

type Props = {
  /** L adresse encodee dans le code. */
  valeur: string;
  /** Cote du code, en pixels. */
  cote?: number;
  /** Legende affichee sous le code. */
  legende?: string;
};

export function CodeQr({ valeur, cote = 148, legende }: Props) {
  const [image, setImage] = useState<string>('');

  useEffect(() => {
    let vivant = true;
    QRCode.toDataURL(valeur, {
      width: cote * 2,
      margin: 1,
      color: { dark: '#000000', light: '#ffffff' },
    })
      .then((url) => {
        if (vivant) {
          setImage(url);
        }
      })
      .catch(() => setImage(''));
    return () => {
      vivant = false;
    };
  }, [valeur, cote]);

  return (
    <figure className="flex flex-col items-center gap-2">
      <div
        className="flex items-center justify-center rounded-petit bg-white p-2"
        style={{ width: cote + 16, height: cote + 16 }}
      >
        {image ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={image} alt={legende ?? valeur} width={cote} height={cote} />
        ) : (
          <span className="h-full w-full animate-pulse rounded bg-muet" />
        )}
      </div>
      {legende ? (
        <figcaption className="text-center text-[13px] text-texte-secondaire">{legende}</figcaption>
      ) : null}
    </figure>
  );
}
