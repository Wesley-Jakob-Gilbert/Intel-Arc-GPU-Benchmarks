# Arc Pro B70 — Blender Cycles Rendering (Blender Open Data Benchmark)

## Hardware

| Component | Spec |
|---|---|
| GPU | Intel Arc Pro B70 32GB GDDR6 (reported by Blender as `Intel(R) Graphics [0xe223]`) |
| CPU | Intel Core i9-14900K (24 cores / 32 threads) |
| RAM | 64GB DDR5-6000 |
| Motherboard | ASUS ROG Maximus Z790 Dark Hero |
| OS | Ubuntu 26.04 LTS |
| PCIe slot | x8 (PCIe 5.0) |

## Software

| Component | Version |
|---|---|
| Blender | 5.1.1 (build 2026-04-14, hash b70da489d7f4) |
| Benchmark launcher CLI | 3.3.0 |
| Benchmark script | 3.1.2 |
| GPU backend | Cycles oneAPI (SYCL), device type `ONEAPI` |

## Results

Rendering throughput in samples per minute (higher is better), as reported by the
official Blender Benchmark launcher. Each scene is rendered for the launcher's 30 s time
limit; the launcher reports the number of samples completed in that window.

| Scene | B70 (ONEAPI) samples/min | i9-14900K (CPU) samples/min | GPU speedup | B70 peak mem (MB) | CPU peak mem (MB) |
|---|---|---|---|---|---|
| monster | 1395.72 | 246.47 | 5.66x | 2521 | 639 |
| junkshop | 959.59 | 196.64 | 4.88x | 7680 | 4755 |
| classroom | 926.08 | 135.16 | 6.85x | 2322 | 647 |

Speedup = B70 samples/min divided by CPU samples/min, computed from the table values.

Raw launcher output (all fields, including per-scene checksums and timings):
[ONEAPI](raw/blender/b70_ONEAPI_20261027.json), [CPU](raw/blender/b70_CPU_20261027.json).

## Methodology and caveats

- **One run per scene and device.** No repeats, so there is no run-to-run variance
  estimate. Treat differences of a few percent as noise.
- **Measured 2026-10-27** (evening, local time); the Blender and launcher versions above
  were current at that time.
- Rendered with the official launcher's non-interactive flow (`benchmark ... --json`), so
  scenes, settings and scoring come from the Blender Open Data benchmark, not custom settings.
- The results were not submitted to opendata.blender.org.
- "Peak mem" is the launcher's `device_peak_memory` field for the selected device.
- Hardware ray tracing was left at the launcher defaults; no on/off comparison is published here.

## Reproducing

The commands below follow the launcher's bundled `README.txt` and `benchmark --help`, with the
versions used here:

```bash
wget https://download.blender.org/release/BlenderBenchmark2.0/launcher/benchmark-launcher-cli-3.3.0-linux.tar.gz
tar -xzf benchmark-launcher-cli-3.3.0-linux.tar.gz
cd benchmark-launcher-cli-3.3.0-linux

./benchmark-launcher-cli blender download --blender-version 5.1.1
./benchmark-launcher-cli devices --blender-version 5.1.1
./benchmark-launcher-cli scenes --blender-version 5.1.1 download monster junkshop classroom

./benchmark-launcher-cli benchmark --blender-version 5.1.1 --device-type ONEAPI --json monster junkshop classroom
./benchmark-launcher-cli benchmark --blender-version 5.1.1 --device-type CPU    --json monster junkshop classroom
```

The exact invocation that produced the stored JSON was not saved, so the benchmark lines above are
reconstructed rather than copied. Requires a working Intel compute runtime
(see [setup/ubuntu-26.04.md](../../setup/ubuntu-26.04.md)).
