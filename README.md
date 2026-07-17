# Intel Arc GPU Benchmarks

Cross-workload GPU compute benchmarks for Intel Arc series GPUs on Linux — covering LLM inference, Blender rendering, and HPC workloads.

The goal is to fill a real gap: Intel's official MLPerf submissions use enterprise multi-GPU configurations on Xeon 6 hosts. This repo covers **consumer and prosumer Arc GPUs** (B580, B70) in real-world single and multi-GPU configurations, with reproducible methodology anyone can run.

---

## Hardware Tested

| Node | CPU | GPU(s) | VRAM | Status |
|---|---|---|---|---|
| Scout Node (Node 1) | Intel Core i9-14900K | Arc Pro B70 32GB | 32GB | Active |
| Xeon Node (Node 2) | Intel Xeon W9-658X | 3× Arc B580 12GB | 36GB | Active |
| Heterogeneous Cluster | Both nodes via Tailscale | B70 + B580s | 44–80GB pooled | Planned |

---

## Benchmark Results

### LLM Inference (llama.cpp SYCL backend)

#### Arc Pro B70 — Solo ([details](results/b70-solo/))

| Model | Type | Quant | Size | ngl | Prompt (t/s) | Generation (t/s) | Date |
|---|---|---|---|---|---|---|---|
| Llama 3.1 8B Instruct | Dense | Q4_K_M | 4.58 GiB | 999 (all GPU) | 1068.94 | 88.49 | 2026-06-16 |
| Llama 3.1 8B Instruct | Dense | Q5_K_M | 5.33 GiB | 999 (all GPU) | 1058.98 | 78.06 | 2026-06-17 |
| Llama 3.1 8B Instruct | Dense | Q8_0 | 7.95 GiB | 999 (all GPU) | 1061.11 | 56.00 | 2026-06-21 |
| Llama 3.1 70B Instruct | Dense | Q4_K_M | 39.59 GiB | 60/80 (hybrid) | 64.64 | 4.04 | 2026-07-09 |
| Llama 3.1 70B Instruct | Dense | Q2_K | 24.56 GiB | 999 (all GPU) | 111.73 | 5.63 | 2026-07-09 |
| Llama 3.1 70B Instruct | Dense | IQ3_XS | 27.29 GiB | 999 (all GPU) | 91.40 | 4.16 | 2026-07-09 |
| Qwen3 8B | Dense | Q4_K_M | 4.68 GiB | 999 (all GPU) | 1036.62 | 81.79 | 2026-07-09 |
| Nemotron Nano 9B v2 | Dense | Q4_K_M | 6.07 GiB | 999 (all GPU) | 676.38 | 22.14 | 2026-07-09 |
| Gemma 3 12B it | Dense | Q4_K_M | 6.79 GiB | 999 (all GPU) | 672.84 | 50.80 | 2026-07-09 |
| DeepSeek-R1-Distill-Qwen 14B | Dense | Q4_K_M | 8.37 GiB | 999 (all GPU) | 497.29 | 47.50 | 2026-07-09 |
| Qwen3 14B | Dense | Q4_K_M | 8.38 GiB | 999 (all GPU) | 570.98 | 49.21 | 2026-07-09 |
| Phi-4 14B | Dense | Q4_K_M | 8.43 GiB | 999 (all GPU) | 545.52 | 52.41 | 2026-07-09 |
| gpt-oss 20B | MoE | MXFP4 | 11.27 GiB | 999 (all GPU) | 861.55 | 50.38 | 2026-07-09 |
| Mistral Small 3.2 24B | Dense | Q4_K_M | 13.34 GiB | 999 (all GPU) | 366.67 | 32.89 | 2026-07-09 |
| Gemma 3 27B it | Dense | Q4_K_M | 15.40 GiB | 999 (all GPU) | 291.04 | 26.18 | 2026-07-09 |
| Qwen3 30B-A3B Instruct | MoE | Q4_K_M | 17.35 GiB | 999 (all GPU) | 1187.50 | 92.95 | 2026-07-09 |
| GLM-4 32B (0414) | Dense | Q4_K_M | 18.32 GiB | 999 (all GPU) | 253.69 | 24.20 | 2026-07-09 |
| Qwen3 32B | Dense | Q4_K_M | 18.40 GiB | 999 (all GPU) | 243.74 | 23.47 | 2026-07-09 |
| LLM-jp-4 32B-A3B thinking | MoE | Q4_K_M | 19.93 GiB | 999 (all GPU) | 946.68 | 80.15 | 2026-07-09 |
| gpt-oss 120B | MoE | MXFP4 | 59.02 GiB | `--n-cpu-moe 22` (hybrid) | 136.42 | 27.69 | 2026-07-09 |
| GLM-4.5-Air | MoE | Q4_K_M | 67.96 GiB | `--n-cpu-moe 31` (hybrid) | 85.37 | 14.36 | 2026-07-09 |

> Prompt throughput is nearly identical across 8B quantizations (compute-bound). Generation scales inversely with model size (memory-bound) for dense models. MoE models recover memory bandwidth, allowing faster generation at the same size. Models exceeding 32GB VRAM — run with `-ngl 60` for hybrid CPU+GPU offload ran significantly slower due to pooling system RAM over PCIe. Compare LLama 70B Q4_K_M that runs hybrid over CPU/GPU at 65 t/s prefill vs. Q2_K which fits fully on-GPU, yielding 112 t/s (nearly 2x increase). See [roofline analysis](docs/roofline-analysis.md) for full breakdown, or the [full results table](results/b70-solo/llm-inference.md) for raw output and methodology on all 21 models.

### Blender Rendering
*Coming soon*

### GROMACS Molecular Dynamics
*Coming soon*

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
