#!/usr/bin/env bash
set -euo pipefail

# Verifica que openspec/config.yaml conserva la configuración personalizada del
# proyecto. `openspec update` regenera skills, pero nunca debe perder estas reglas.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(dirname "$SCRIPT_DIR")"
CONFIG="$RAIZ/openspec/config.yaml"

if [[ ! -f "$CONFIG" ]]; then
  echo "check_openspec_config: falta openspec/config.yaml" >&2
  exit 1
fi

ERRORES=0
comprobar() {
  local patron="$1" descripcion="$2"
  if ! grep -qE "$patron" "$CONFIG"; then
    echo "check_openspec_config: falta $descripcion" >&2
    ERRORES=1
  fi
}

comprobar '^# tolochatracks:config-personalizada$' 'el marcador de configuración personalizada'
comprobar '^schema: spec-driven$' 'el esquema spec-driven'
comprobar 'TolochaTracks' 'el contexto del proyecto'
comprobar 'Cada fusión en dev dispara la versión' 'la regla de release al fusionar en dev'
comprobar 'GPX 1\.1 y JSON' 'la regla de exportación'
comprobar 'OpenStreetMap' 'la atribución de mapas libres'
comprobar 'CREACIÓN DE CHANGES' 'las reglas de creación de changes'

if [[ "$ERRORES" -gt 0 ]]; then
  echo "check_openspec_config: la configuración personalizada de OpenSpec se ha perdido." >&2
  echo "Restaura openspec/config.yaml desde git antes de continuar." >&2
  exit 1
fi

echo "check_openspec_config: configuración personalizada intacta"
