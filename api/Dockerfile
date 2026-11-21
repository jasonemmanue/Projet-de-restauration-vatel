# Image de l'API en deux étapes : la première construit les dépendances, la seconde ne garde que l'exécution,
# lancée par un utilisateur sans droits.

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
    PATH="/opt/venv/bin:$PATH"
RUN groupadd --system vatel && useradd --system --gid vatel --home-dir /app --shell /usr/sbin/nologin vatel
WORKDIR /app
COPY --from=construction /opt/venv /opt/venv
COPY --chown=vatel:vatel alembic.ini ./
COPY --chown=vatel:vatel alembic ./alembic
COPY --chown=vatel:vatel app ./app
USER vatel
EXPOSE 8000

# Forme shell, pour que ${PORT} posé par Railway soit lu. La migration passe avant le service : si elle
# échoue, le conteneur s'arrête et Railway garde la version précédente. Le relais de Railway n'a pas
# d'adresse fixe, d'où forwarded-allow-ips ; l'adresse du client est relue côté API (app/core/securite.py).
CMD alembic upgrade head && exec uvicorn app.main:creer_application_uvicorn --factory --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers --forwarded-allow-ips="*"
