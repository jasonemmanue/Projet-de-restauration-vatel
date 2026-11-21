# Role du fichier : construit le site public (export statique Next.js) et le sert par nginx sur Railway.
# Les liens NEXT_PUBLIC_* sont figes au build : Railway transmet les variables du service en ARG.
FROM node:20-alpine AS build
WORKDIR /site
ARG NEXT_PUBLIC_LIEN_APPLICATION=https://app-web-production-34865097.up.railway.app
ARG NEXT_PUBLIC_LIEN_PLAY=
ARG NEXT_PUBLIC_LIEN_APP_STORE=
ENV NEXT_PUBLIC_LIEN_APPLICATION=$NEXT_PUBLIC_LIEN_APPLICATION \
    NEXT_PUBLIC_LIEN_PLAY=$NEXT_PUBLIC_LIEN_PLAY \
    NEXT_PUBLIC_LIEN_APP_STORE=$NEXT_PUBLIC_LIEN_APP_STORE \
    NEXT_TELEMETRY_DISABLED=1
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY deploiement/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /site/out /usr/share/nginx/html
ENV PORT=8080
EXPOSE 8080
