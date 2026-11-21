# Role du fichier : construit l application Flutter web et la sert par nginx sur Railway.
# Deux services l utilisent : app-web (ENTREE vide, accueil grand public) et back-office
# (ENTREE=/connexion). Les valeurs viennent des variables du service, transmises en ARG au build.
# Version de Flutter figee sur celle du poste et de la CI : la stable suivante casse des paquets.
FROM ghcr.io/cirruslabs/flutter:3.38.4 AS build
ARG API_URL=https://projet-de-restauration-vatel-production.up.railway.app/api/v1
ARG SITE_URL=https://site-web-production-dc1229af.up.railway.app
ARG ENTREE=
# Valeurs Firebase web, au format JSON de --dart-define-from-file. Vide : pas de notifications.
ARG FIREBASE_DEFINES={}
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN printf '%s' "$FIREBASE_DEFINES" > firebase.defines \
 && flutter build web --release \
      --dart-define=API_URL=${API_URL} \
      --dart-define=SITE_URL=${SITE_URL} \
      --dart-define=ENTREE=${ENTREE} \
      --dart-define-from-file=firebase.defines

FROM nginx:1.27-alpine
COPY deploiement/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html
ENV PORT=8080
EXPOSE 8080
