# Intel Arc GPU Benchmarks

Cross-workload GPU compute benchmarks for Intel Arc series GPUs on Linux — covering LLM inference, Blender rendering, and HPC workloads.

The goal is to fill a real gap: Intel's official MLPerf submissions use enterprise multi-GPU configurations on Xeon 6 hosts. This repo covers **consumer and prosumer Arc GPUs** (B580, B70) in real-world single and multi-GPU configurations, with reproducible methodology anyone can run.

---

## Hardware Tested

| Node | CPU | GPU(s) | VRAM | Status |
|---|---|---|---|---|
| Scout Node (Node 1) | Intel Core i9-14900K | Arc Pro B70 32GB | 32GB | Active |
| Xeon Node (Node 2) | Intel Xeon W9-658X | 3–4× Arc B580 12GB | 36–48GB | Planned |
| Heterogeneous Cluster | Both nodes via Tailscale | B70 + B580s | 44–80GB pooled | Planned |

---

## Benchmark Results

### LLM Inference (llama.cpp SYCL backend)

#### Arc Pro B70 — Solo ([details](results/b70-solo/))

| Model | Quant | Size | ngl | Prompt (t/s) | Generation (t/s) | Date |
|---|---|---|---|---|---|---|
| Llama 3.1 8B Instruct | Q4_K_M | 4.58 GiB | 999 (all GPU) | 1068.94 | 88.49 | 2026-06-16 |
| Llama 3.1 8B Instruct | Q5_K_M | 5.33 GiB | 999 (all GPU) | 1058.98 | 78.06 | 2026-06-17 |
| Llama 3.1 8B Instruct | Q8_0 | 7.95 GiB | 999 (all GPU) | 1053.28 | 56.01 | 2026-06-17 |
| Llama 3.1 70B Instruct | Q4_K_M | 39.59 GiB | 60/80 (hybrid) | 65.38 | 4.07 | 2026-06-17 |
| Llama 3.1 70B Instruct | Q2_K | 24.56 GiB | 999 (all GPU) | 112.65 | 5.64 | 2026-06-17 |

> Prompt throughput is nearly identical across 8B quantizations (compute-bound). Generation scales inversely with model size (memory-bound). The 70B Q4_K_M exceeds 32GB VRAM — run with `-ngl 60` for hybrid CPU+GPU offload. Q2_K fits fully on-GPU, yielding 112 t/s prefill vs 65 t/s hybrid. See [roofline analysis](docs/roofline-analysis.md) for full breakdown.

*70B IQ3_XS (fully GPU-accelerated) in progress.*

### Blender Rendering
*Coming soon*

### GROMACS Molecular Dynamics
*Coming soon — pending RTX 5090 acquisition (Q1 2027)*

---

## Reproducing These Results

### Prerequisites
- Ubuntu 26.04 LTS
- Intel Arc GPU (B-series)
- See [setup/ubuntu-26.04.md](setup/ubuntu-26.04.md) for full driver install guide

### Run the benchmark
```bash
source /opt/intel/oneapi/setvars.sh
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
cmake -B build -DGGML_SYCL=ON -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx
cmake --build build --config Release -j$(nproc)

# Download model
wget https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf

# Run benchmark
./build/bin/llama-bench -m Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf -ngl 999 -p 512 -n 128
```

Or use the automated script: [scripts/run-bench.sh](scripts/run-bench.sh) *(coming soon)*

---

## Software Versions

| Component | Version |
|---|---|
| OS | Ubuntu 26.04 LTS (kernel 7.0.0-22-generic) |
| llama.cpp | b9672-74ade5274 |
| Intel oneAPI | 2026.0.0 |
| intel-opencl-icd | 26.05.37020.3-1 |
| libze-intel-gpu1 | 26.05.37020.3-1 |

---

## Repo Structure

```
Intel-Arc-GPU-Benchmarks/
├── README.md                        # overview and summary results
├── setup/
│   └── ubuntu-26.04.md              # driver install guide (oneAPI, Level Zero, OpenCL)
├── results/
│   ├── b70-solo/                    # Arc Pro B70 standalone benchmarks
│   ├── b580-solo/                   # Arc B580 standalone benchmarks
│   ├── b580-multi/                  # 2–4× B580 multi-GPU benchmarks
│   └── b70-b580-heterogeneous/      # mixed B70 + B580 cluster benchmarks
├── docs/
│   └── roofline-analysis.md         # roofline model analysis of quantization scaling
├── hardware/
│   └── node-configs.md              # exact hardware specs per test system
└── scripts/
    └── run-bench.sh                 # reproducible benchmark automation script
```

---

## Contributing

If you have an Intel Arc GPU and want to contribute results, open a PR with your results file following the format in [results/b70-solo/](results/b70-solo/). Include your exact hardware, software versions, and the raw llama-bench output.

---

## Related Work

- [Intel MLPerf Inference v6.0 results](https://newsroom.intel.com/artificial-intelligence/intel-arc-pro-b-series-gpus-and-xeon-6-shine-in-mlperf-inference-v5-1) — official 4× B70 enterprise results
- [llama.cpp SYCL backend](https://github.com/ggerganov/llama.cpp/blob/master/docs/backend/SYCL.md) — upstream docs
- [Intel oneAPI](https://www.intel.com/content/www/us/en/developer/tools/oneapi/overview.html)
