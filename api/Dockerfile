# Image de l'API en deux étapes : la première construit les dépendances, la seconde ne garde que l'exécution.
# L'API tourne sous un utilisateur sans droits ; seul le lancement passe par root, le temps de rendre le volume
# des médias accessible à cet utilisateur, puis setpriv abandonne root avant toute autre commande.

FROM python:3.12-slim AS construction
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /construction
COPY requirements.txt .
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install -r requirements.txt

FROM python:3.12-slim AS execution
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    STOCKAGE_DOSSIER=/app/medias \
    HOME=/app
RUN groupadd --system vatel && useradd --system --gid vatel --home-dir /app --shell /usr/sbin/nologin vatel
WORKDIR /app
COPY --from=construction /opt/venv /opt/venv
COPY --chown=vatel:vatel alembic.ini ./
COPY --chown=vatel:vatel alembic ./alembic
COPY --chown=vatel:vatel app ./app
COPY --chown=vatel:vatel demo ./demo
RUN mkdir -p /app/medias && chown vatel:vatel /app/medias
EXPOSE 8000

# Forme shell, pour que ${PORT} posé par Railway soit lu. Le volume monté par Railway appartient à root : on
# le rend à vatel, puis tout le reste tourne sous vatel. La migration passe avant le service : si elle
# échoue, le conteneur s'arrête et Railway garde la version précédente.
CMD chown -R vatel:vatel "${STOCKAGE_DOSSIER}" && exec setpriv --reuid=vatel --regid=vatel --init-groups sh -c 'alembic upgrade head && exec uvicorn app.main:creer_application_uvicorn --factory --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers --forwarded-allow-ips="*"'
