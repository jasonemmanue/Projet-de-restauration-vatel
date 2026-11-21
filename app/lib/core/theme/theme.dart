// Role du fichier : construire les deux themes de l application a partir des palettes de la charte.
// Regles tenues ici : aucune ombre, rayons 14 22 28, boutons en pilule de 52, Plus Jakarta Sans,
// titres en graisse 800 avec interlettrage -0,04em, transitions de la meme famille partout.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../responsive/type_ecran.dart';
import 'couleurs.dart';

/// Nom de la famille de police embarquee dans les ressources.
const String famillePolice = 'PlusJakartaSans';

/// Transition commune a toutes les pages : fondu et montee courte, de 240 ms.
class TransitionDouce extends PageTransitionsBuilder {
  /// Construit la transition commune.
  const TransitionDouce();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> animationSecondaire,
    Widget enfant,
  ) {
    final CurvedAnimation adoucie = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: adoucie,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(adoucie),
        child: enfant,
      ),
    );
  }
}

/// Construit le theme clair ou sombre de l application.
ThemeData construireTheme({required bool sombre}) {
  final Palette palette = sombre ? paletteSombre : paletteClaire;
  final Brightness luminosite = sombre ? Brightness.dark : Brightness.light;

  final ColorScheme schema = ColorScheme(
    brightness: luminosite,
    primary: palette.accent,
    onPrimary: palette.surAccent,
    primaryContainer: palette.accentDoux,
    onPrimaryContainer: palette.texte,
    secondary: palette.accent,
    onSecondary: palette.surAccent,
    secondaryContainer: palette.accentDoux,
    onSecondaryContainer: palette.texte,
    tertiary: palette.succes,
    onTertiary: palette.surAccent,
    error: palette.danger,
    onError: palette.surAccent,
    errorContainer: palette.danger,
    onErrorContainer: palette.surAccent,
    surface: palette.surface,
    onSurface: palette.texte,
    surfaceContainerLowest: palette.surface,
    surfaceContainerLow: palette.fond,
    surfaceContainer: palette.muet,
    surfaceContainerHigh: palette.muet,
    surfaceContainerHighest: palette.muet,
    onSurfaceVariant: palette.texteSecondaire,
    outline: palette.filet,
    outlineVariant: palette.filet,
    inverseSurface: palette.contraste,
    onInverseSurface: palette.surContraste,
    shadow: const Color(0x00000000),
    scrim: const Color(0x66000000),
  );

  // Les tailles de reference sont celles du telephone : les ecrans plus larges
  // les ajustent par MesuresTexte, sans toucher au theme.
  const MesuresTexte mesures = MesuresTexte(
    titreEcran: 24,
    titreSection: 20,
    sousTitre: 17,
    corps: 14,
    corpsSecondaire: 13,
    bouton: 15,
    onglet: 12,
    mention: 11,
    montant: 28,
  );

  TextStyle titre(double taille) => TextStyle(
        fontFamily: famillePolice,
        fontSize: taille,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04 * taille,
        color: palette.texte,
        height: 1.15,
      );

  TextStyle corps(double taille, {Color? couleur, FontWeight graisse = FontWeight.w500}) => TextStyle(
        fontFamily: famillePolice,
        fontSize: taille,
        fontWeight: graisse,
        color: couleur ?? palette.texte,
        height: 1.35,
      );

  final TextTheme typographie = TextTheme(
    displayLarge: titre(mesures.montant),
    headlineLarge: titre(mesures.titreEcran),
    headlineMedium: titre(mesures.titreSection),
    titleLarge: titre(mesures.sousTitre),
    titleMedium: corps(mesures.corps, graisse: FontWeight.w700),
    bodyLarge: corps(mesures.corps),
    bodyMedium: corps(mesures.corpsSecondaire, couleur: palette.texteSecondaire),
    labelLarge: corps(mesures.bouton, graisse: FontWeight.w700),
    labelMedium: corps(mesures.onglet, graisse: FontWeight.w600),
    labelSmall: corps(mesures.mention, couleur: palette.texteSecondaire, graisse: FontWeight.w500),
  );

  final OutlineInputBorder bordureChamp = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Mesures.rayonPetit),
    borderSide: BorderSide(color: palette.filet),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: luminosite,
    colorScheme: schema,
    scaffoldBackgroundColor: palette.fond,
    canvasColor: palette.fond,
    fontFamily: famillePolice,
    textTheme: typographie,
    splashFactory: InkSparkle.splashFactory,
    // La profondeur vient des aplats et des filets : aucune ombre nulle part.
    shadowColor: const Color(0x00000000),
    extensions: <ThemeExtension<dynamic>>[JetonsCouleur(palette)],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        // Sur iPhone, la transition native garde le retour par glissement.
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: TransitionDouce(),
        TargetPlatform.windows: TransitionDouce(),
        TargetPlatform.linux: TransitionDouce(),
        TargetPlatform.fuchsia: TransitionDouce(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.fond,
      foregroundColor: palette.texte,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: titre(mesures.titreSection),
      systemOverlayStyle: sombre
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: const Color(0x00000000),
              systemNavigationBarColor: const Color(0x00000000),
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: const Color(0x00000000),
              systemNavigationBarColor: const Color(0x00000000),
            ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Mesures.rayonCarte),
        side: BorderSide(color: palette.filet),
      ),
    ),
    dividerTheme: DividerThemeData(color: palette.filet, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.surAccent,
        disabledBackgroundColor: palette.muet,
        disabledForegroundColor: palette.texteSecondaire,
        minimumSize: const Size.fromHeight(Mesures.hauteurBouton),
        elevation: 0,
        textStyle: typographie.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.texte,
        minimumSize: const Size.fromHeight(Mesures.hauteurBouton),
        side: BorderSide(color: palette.filet),
        textStyle: typographie.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        minimumSize: const Size(Mesures.cibleTactile, Mesures.cibleTactile),
        textStyle: typographie.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(Mesures.cibleTactile, Mesures.cibleTactile),
        foregroundColor: palette.texte,
      ),
    ),
    iconTheme: IconThemeData(color: palette.texte, size: 22),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      modalElevation: 0,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Mesures.rayonGrand)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.accentDoux,
      elevation: 0,
      height: 68,
      // Les libelles restent visibles, meme sur l onglet inactif.
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (Set<WidgetState> etats) => typographie.labelMedium!.copyWith(
          color: etats.contains(WidgetState.selected) ? palette.accent : palette.texteSecondaire,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (Set<WidgetState> etats) => IconThemeData(
          size: 24,
          color: etats.contains(WidgetState.selected) ? palette.accent : palette.texteSecondaire,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.accentDoux,
      selectedIconTheme: IconThemeData(color: palette.accent),
      unselectedIconTheme: IconThemeData(color: palette.texteSecondaire),
      selectedLabelTextStyle: typographie.labelMedium!.copyWith(color: palette.accent),
      unselectedLabelTextStyle: typographie.labelMedium!.copyWith(color: palette.texteSecondaire),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.champ,
      hintStyle: typographie.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: bordureChamp,
      enabledBorder: bordureChamp,
      focusedBorder: bordureChamp.copyWith(
        borderSide: BorderSide(color: palette.accent, width: 2),
      ),
      errorBorder: bordureChamp.copyWith(borderSide: BorderSide(color: palette.danger)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.contraste,
      contentTextStyle: typographie.bodyLarge!.copyWith(color: palette.surContraste),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mesures.rayonPetit)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.muet,
      selectedColor: palette.accentDoux,
      labelStyle: typographie.labelMedium!,
      side: BorderSide(color: palette.filet),
      shape: const StadiumBorder(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.accent,
      linearTrackColor: palette.muet,
      circularTrackColor: palette.muet,
    ),
  );
}
