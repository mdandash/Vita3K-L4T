This patch adds unsafe Vulkan memory-mapping overrides for Tegra/NVIDIA devices.

What changed:
- Exposes the memory-mapping dropdown even when the UI would normally hide it.
- Lets you force a mapping method at runtime with environment variables.
- On Tegra/NVIDIA devices, it exposes Vulkan mapping methods more aggressively.

Environment variables:
- VITA3K_SHOW_ALL_MAPPING_METHODS=1
  Show all mapping methods in the UI even if the GPU mask hides them.

- VITA3K_FORCE_MAPPING_METHOD=<method>
  Force a mapping method at runtime.
  Valid values:
    disabled
    double-buffer
    external-host
    page-table
    native-buffer

- VITA3K_UNSAFE_TEGRA_MAPPING=1
  Force-expose Vulkan memory-mapping methods on Tegra/NVIDIA devices even if the driver did not fully advertise support.

Suggested Linux test:
  VITA3K_SHOW_ALL_MAPPING_METHODS=1 \
  VITA3K_FORCE_MAPPING_METHOD=double-buffer \
  VITA3K_UNSAFE_TEGRA_MAPPING=1 \
  ./Vita3K

Suggested Android source test:
- Build the APK from this source.
- If you cannot pass env vars on-device easily, hardcode config.current_config.memory_mapping or add a tiny UI default later.

Warnings:
- This is intentionally unsafe and may crash or render incorrectly.
- native-buffer is still Android-oriented in upstream code; it may not work on Linux.
