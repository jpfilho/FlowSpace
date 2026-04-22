#!/bin/bash

REPO_DIR="/tmp/FlowSpace"
SERVE_DIR="/var/www/flowspace"
REPO_URL="https://github.com/jpfilho/FlowSpace.git"

echo "========================================"
echo "  FlowSpace - Deploy via Git"
echo "========================================"

# Clona o repositório se ainda não existir
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[1/3] Clonando repositorio..."
  git clone "$REPO_URL" "$REPO_DIR"
else
  echo "[1/3] Atualizando repositorio..."
  cd "$REPO_DIR"
  git pull origin main
fi

# Copia os arquivos do build/web para o diretório servido
echo "[2/3] Copiando build para $SERVE_DIR..."
cp -r "$REPO_DIR/build/web/." "$SERVE_DIR/"

echo "[3/3] Deploy concluido com sucesso!"
echo "========================================"
