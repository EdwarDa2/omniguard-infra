#!/usr/bin/env bash
# ============================================================
# OmniGuard SOC - Generador de Secrets para Desarrollo
# ============================================================

set -euo pipefail

SECRETS_DIR="$(dirname "$0")/../secrets"

echo "Generando secrets de desarrollo en $SECRETS_DIR..."

# DB Password
openssl rand -base64 32 > "$SECRETS_DIR/db_password.txt"
echo "✓ db_password.txt"

# PASETO Local Key (32 bytes = 256 bits para XChaCha20-Poly1305)
openssl rand -base64 32 > "$SECRETS_DIR/paseto_private_key.txt"
echo "✓ paseto_private_key.txt (local key)"

# PASETO Public/Private Key Pair (Ed25519)
openssl genpkey -algorithm Ed25519 -out "$SECRETS_DIR/paseto_ed25519_private.pem" 2>/dev/null
openssl pkey -in "$SECRETS_DIR/paseto_ed25519_private.pem" -pubout -out "$SECRETS_DIR/paseto_ed25519_public.pem" 2>/dev/null

# Convertir a base64 para uso en config
base64 -w 0 "$SECRETS_DIR/paseto_ed25519_private.pem" > "$SECRETS_DIR/paseto_private_key_full.txt"
base64 -w 0 "$SECRETS_DIR/paseto_ed25519_public.pem" > "$SECRETS_DIR/paseto_public_key_full.txt"

# Para la implementación simplificada, usar claves base64
cp "$SECRETS_DIR/paseto_private_key_full.txt" "$SECRETS_DIR/paseto_private_key.txt"
cp "$SECRETS_DIR/paseto_public_key_full.txt" "$SECRETS_DIR/paseto_public_key.txt"

echo "✓ paseto_private_key.txt (Ed25519 private)"
echo "✓ paseto_public_key.txt (Ed25519 public)"

# Grafana Password
openssl rand -base64 16 > "$SECRETS_DIR/grafana_password.txt"
echo "✓ grafana_password.txt"

echo ""
echo "=========================================="
echo "Secrets generados exitosamente"
echo "=========================================="
echo ""
echo "IMPORTANTE:"
echo "1. Estos secrets son SOLO para desarrollo local"
echo "2. En producción, usar Docker Secrets / HashiCorp Vault / AWS Secrets Manager"
echo "3. NUNCA commitear los archivos .txt reales (están en .gitignore)"
echo "4. Los archivos .example SÍ se pueden commitear"
echo ""
echo "Para usar en desarrollo:"
echo "  cd infra/omniguard-infra"
echo "  docker compose up -d"