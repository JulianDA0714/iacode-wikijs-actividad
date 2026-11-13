#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/wikijs-bootstrap.log | logger -t wikijs-bootstrap -s 2>/dev/console) 2>&1

echo "Iniciando configuracion de Wiki.js - Actividad 5"

dnf update -y
dnf install -y docker git awscli jq

systemctl enable --now docker

mkdir -p /opt/wikijs

echo "Docker instalado y servicio iniciado"


echo "Instalando Docker Compose"

mkdir -p /usr/local/lib/docker/cli-plugins

COMPOSE_VERSION="v2.40.3"

curl -fSL \
  "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

docker compose version

echo "Instalando Docker Buildx"

BUILDX_VERSION="v0.20.1"

curl -fSL --retry 3 \
  "https://github.com/docker/buildx/releases/download/$BUILDX_VERSION/buildx-$BUILDX_VERSION.linux-amd64" \
  -o /usr/local/lib/docker/cli-plugins/docker-buildx

chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

docker buildx version

echo "Docker Buildx instalado correctamente"

echo "Descargando proyecto desde GitHub"

git clone \
  https://github.com/JulianDA0714/iacode-wikijs-actividad5.git \
  /opt/wikijs

cd /opt/wikijs

echo "Proyecto descargado correctamente"


echo "Configurando conexiones a RDS y Redis"

SECRET_ARN="${postgres_secret_arn}"
AWS_REGION="${aws_region}"

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text)

DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

if [ -z "$DB_PASSWORD" ] || [ "$DB_PASSWORD" = "null" ]; then
  echo "ERROR: No se pudo recuperar la contraseña de RDS"
  exit 1
fi


umask 077

export DB_PASSWORD

export WIKI_DB_HOST="${postgres_endpoint}"
export WIKI_REDIS_HOST="${redis_endpoint}"

python3 - <<'PY'
import os
from pathlib import Path


def compose_value(value):
    value = value.replace("\\", "\\\\")
    value = value.replace("'", "\\'")
    value = value.replace("\n", "\\n")
    value = value.replace("\r", "\\r")
    return "'" + value + "'"

variables = {
    "DB_HOST": os.environ["WIKI_DB_HOST"],
    "DB_USER": "wikiadmin",
    "DB_PASSWORD": os.environ["DB_PASSWORD"],
    "DB_NAME": "wikijs",
    "REDIS_HOST": os.environ["WIKI_REDIS_HOST"],
}

contenido = "\n".join(
    f"{clave}={compose_value(valor)}"
    for clave, valor in variables.items()
) + "\n"

Path("/opt/wikijs/.env.aws").write_text(contenido)
PY

chmod 600 /opt/wikijs/.env.aws

unset SECRET_JSON DB_PASSWORD WIKI_DB_HOST WIKI_REDIS_HOST

echo "Variables de conexion configuradas"

echo "Descargando certificado SSL de Amazon RDS"

curl -fSL --retry 3 \
  https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
  -o /opt/wikijs/rds-global-bundle.pem

chmod 644 /opt/wikijs/rds-global-bundle.pem

echo "Certificado SSL de RDS descargado correctamente"

echo "Iniciando contenedores de Wiki.js y Flask"

cd /opt/wikijs

docker compose \
  --env-file .env.aws \
  -f compose.aws.yaml \
  up -d --build

echo "Verificando contenedores"

docker compose \
  --env-file .env.aws \
  -f compose.aws.yaml \
  ps

echo "Inicializacion de Wiki.js completada"

