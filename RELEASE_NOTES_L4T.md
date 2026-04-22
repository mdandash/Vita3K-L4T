# Vita3K L4T Tegra mapping test build

This build includes a Tegra-oriented mapping override patch.

## What changed
- exposes memory-mapping selection more aggressively on Tegra/NVIDIA
- adds runtime env overrides:
  - `VITA3K_SHOW_ALL_MAPPING_METHODS=1`
  - `VITA3K_FORCE_MAPPING_METHOD=double-buffer|external-host|page-table|native-buffer|disabled`
  - `VITA3K_UNSAFE_TEGRA_MAPPING=1`

## Build
```bash
sudo apt update
sudo apt install -y git cmake ninja-build pkg-config libsdl2-dev libgtk-3-dev gcc g++ zip tar xdg-desktop-portal openssl libssl-dev
git submodule update --init --recursive
./build_l4t_release.sh
```

## Output
The script writes a staged folder plus `.tar.gz` and `.zip` under `out/`.

## Suggested runtime tests
```bash
./run-vita3k-tegra-double-buffer.sh
./run-vita3k-tegra-page-table.sh
```
