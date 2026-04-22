#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PRESET="${PRESET:-linux-ninja-gnu}"
CONFIG="${CONFIG:-Release}"
PKG_NAME="${PKG_NAME:-Vita3K-L4T-TegraMapping}"
OUT_DIR="${OUT_DIR:-$ROOT/out}"
BUILD_DIR="$ROOT/build/$PRESET"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }
}

need cmake
need ninja
need zip
need tar

if [ ! -f "$ROOT/CMakePresets.json" ]; then
  echo "Run this from the Vita3K source root." >&2
  exit 1
fi

if [ ! -d "$ROOT/external" ]; then
  echo "Submodules look missing. Run:" >&2
  echo "  git submodule update --init --recursive" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "[1/5] Configuring with preset: $PRESET"
cmake --preset "$PRESET"

echo "[2/5] Building config: $CONFIG"
cmake --build "$BUILD_DIR" --config "$CONFIG" -j"$(nproc)"

BIN_DIR=""
for cand in \
  "$BUILD_DIR/bin/$CONFIG" \
  "$BUILD_DIR/bin" \
  "$BUILD_DIR/vita3k/$CONFIG" \
  "$BUILD_DIR/vita3k"; do
  if [ -x "$cand/Vita3K" ] || [ -x "$cand/vita3k" ]; then
    BIN_DIR="$cand"
    break
  fi
done

if [ -z "$BIN_DIR" ]; then
  echo "Could not find built Vita3K binary under $BUILD_DIR" >&2
  find "$BUILD_DIR" -maxdepth 4 \( -name Vita3K -o -name vita3k \) -type f >&2 || true
  exit 1
fi

BIN_NAME="Vita3K"
[ -x "$BIN_DIR/Vita3K" ] || BIN_NAME="vita3k"
VERSION_TAG="$(git rev-parse --short HEAD 2>/dev/null || echo manual)"
STAMP="$(date +%Y%m%d-%H%M%S)"
STAGE="$OUT_DIR/${PKG_NAME}-${VERSION_TAG}-${STAMP}"

rm -rf "$STAGE"
mkdir -p "$STAGE"

echo "[3/5] Staging release files from: $BIN_DIR"
cp -a "$BIN_DIR/$BIN_NAME" "$STAGE/Vita3K"

for extra in data lang shaders-builtin; do
  if [ -d "$BIN_DIR/$extra" ]; then
    cp -a "$BIN_DIR/$extra" "$STAGE/"
  elif [ -d "$ROOT/$extra" ]; then
    cp -a "$ROOT/$extra" "$STAGE/"
  fi
done

if [ -f "$ROOT/TEGRA_MAPPING_PATCH_README.txt" ]; then
  cp -a "$ROOT/TEGRA_MAPPING_PATCH_README.txt" "$STAGE/"
fi
cp -a "$ROOT/COPYING.txt" "$STAGE/"

cat > "$STAGE/run-vita3k-tegra-double-buffer.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
export VITA3K_SHOW_ALL_MAPPING_METHODS=1
export VITA3K_FORCE_MAPPING_METHOD=double-buffer
export VITA3K_UNSAFE_TEGRA_MAPPING=1
cd "$DIR"
exec ./Vita3K "$@"
EOF
chmod +x "$STAGE/run-vita3k-tegra-double-buffer.sh"

cat > "$STAGE/run-vita3k-tegra-page-table.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
export VITA3K_SHOW_ALL_MAPPING_METHODS=1
export VITA3K_FORCE_MAPPING_METHOD=page-table
export VITA3K_UNSAFE_TEGRA_MAPPING=1
cd "$DIR"
exec ./Vita3K "$@"
EOF
chmod +x "$STAGE/run-vita3k-tegra-page-table.sh"

cat > "$STAGE/README-L4T-RELEASE.txt" <<EOF
Vita3K L4T release package

Build preset: $PRESET
Config: $CONFIG
Git commit: $VERSION_TAG

Contents:
- Vita3K binary
- data/
- lang/
- shaders-builtin/
- Tegra mapping patch notes
- helper launchers for forced mapping methods

Suggested test order on Tegra X1:
1) ./run-vita3k-tegra-double-buffer.sh
2) ./run-vita3k-tegra-page-table.sh

If you want to run directly:
VITA3K_SHOW_ALL_MAPPING_METHODS=1 VITA3K_FORCE_MAPPING_METHOD=double-buffer VITA3K_UNSAFE_TEGRA_MAPPING=1 ./Vita3K
EOF

echo "[4/5] Packaging archives"
( cd "$OUT_DIR" && tar -czf "$(basename "$STAGE").tar.gz" "$(basename "$STAGE")" )
( cd "$OUT_DIR" && zip -qr "$(basename "$STAGE").zip" "$(basename "$STAGE")" )

echo "[5/5] Done"
echo "Staged release: $STAGE"
echo "Tarball: $OUT_DIR/$(basename "$STAGE").tar.gz"
echo "Zip: $OUT_DIR/$(basename "$STAGE").zip"
