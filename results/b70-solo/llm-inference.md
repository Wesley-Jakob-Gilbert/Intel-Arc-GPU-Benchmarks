# Arc Pro B70 — LLM Inference Benchmarks (llama.cpp SYCL)

## Hardware

| Component | Spec |
|---|---|
| GPU | Intel Arc Pro B70 32GB GDDR6 |
| CPU | Intel Core i9-14900K |
| RAM | 64GB DDR5-6000 |
| Motherboard | ASUS ROG Maximus Z790 Dark Hero |
| OS | Ubuntu 26.04 LTS (kernel 7.0.0-22-generic) |
| PCIe slot | x8 (PCIe 5.0) |

## Software

| Component | Version |
|---|---|
| llama.cpp | b9739-845282461 |
| Backend | SYCL (Intel oneAPI) |
| oneAPI compiler | 2026.0.0 |
| intel-opencl-icd | 26.05.37020.3-1 |
| libze-intel-gpu1 | 26.05.37020.3-1 |

## Benchmark Command

```bash
source /opt/intel/oneapi/setvars.sh
./build/bin/llama-bench -m <model.gguf> -ngl 999 -p 512 -n 128
```

- `-ngl 999` — offload all layers to GPU (use lower value for models exceeding VRAM)
- `-p 512` — 512 token prompt processing test
- `-n 128` — 128 token generation test

---

## Results

### Llama 3.1 8B Instruct

| Type | Quant | Size | Prompt (t/s) | Generation (t/s) | Date |
|---|---|---|---|---|---|
| Dense | Q4_K_M | 4.58 GiB | 1068.94 ± 0.86 | 88.49 ± 0.10 | 2026-06-16 |
| Dense | Q5_K_M | 5.33 GiB | 1058.98 ± 3.23 | 78.06 ± 0.05 | 2026-06-17 |
| Dense | Q8_0 | 7.95 GiB | 1061.11 ± 15.84 | 56.00 ± 0.03 | 2026-06-21 |

> **Note:** Q8_0 fits comfortably in 32GB VRAM (7.95 GiB used). Most consumer GPUs (8–16GB) cannot run Q8_0 on an 8B model at all. Prompt throughput is nearly identical to Q4_K_M (1061 vs 1068 t/s), but generation is lower (56 vs 88 t/s) due to higher memory bandwidth demand per token. Generation throughput is unchanged vs b9672 — Q8_0 tg128 on Arc B70 appears memory-bandwidth-limited regardless of build. PR #21527 did not change this result.

Raw output:
```
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | SYCL       | 999 |           pp512 |       1068.94 ± 0.86 |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | SYCL       | 999 |           tg128 |         88.49 ± 0.10 |
| llama 8B Q8_0                  |   7.95 GiB |     8.03 B | SYCL       | 999 |           pp512 |       1061.11 ± 15.84 |
| llama 8B Q8_0                  |   7.95 GiB |     8.03 B | SYCL       | 999 |           tg128 |          56.00 ± 0.03 |

build: 845282461 (9739)
```

---

### Llama 3.1 70B Instruct

> **Note:** The 70B Q4_K_M model (39.59 GiB) exceeds the B70's 32GB VRAM. These results use **hybrid CPU+GPU offloading** — 60 of 80 layers on GPU, remaining 20 layers on CPU (64GB DDR5-6000). This demonstrates the memory wall boundary for a single 32GB GPU. Fully GPU-accelerated results will follow with smaller quantizations (Q2_K / IQ3_XS).

| Type | Quant | Size | ngl | Mode | Prompt (t/s) | Generation (t/s) | Date |
|---|---|---|---|---|---|---|---|
| Dense | Q4_K_M | 39.59 GiB | 60/80 | Hybrid GPU+CPU | 64.64 ± 0.27 | 4.04 ± 0.01 | 2026-07-09 |
| Dense | Q2_K | 24.56 GiB | 999 | All GPU | 111.73 ± 0.12 | 5.63 ± 0.01 | 2026-07-09 |
| Dense | IQ3_XS | 27.29 GiB | 999 | All GPU | 91.40 ± 0.21 | 4.16 ± 0.00 | 2026-07-09 |

> **Note:** Q2_K (24.56 GiB) fits fully within 32GB VRAM — prompt throughput jumps from 65 → 112 t/s vs hybrid Q4_K_M, confirming the CPU offload overhead cost. IQ3_XS (27.29 GiB) also fits fully on-GPU but is larger than Q2_K, yielding lower prefill (91 t/s) and similar generation (4.16 t/s). Generation across all 70B quantizations is memory-bandwidth-limited regardless of quant level. Reconfirmed on build b9739 (845282461) — all three within noise of the original b9672 run.

Raw output:
```
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 70B Q4_K - Medium        |  39.59 GiB |    70.55 B | SYCL       |  60 |           pp512 |         64.64 ± 0.27 |
| llama 70B Q4_K - Medium        |  39.59 GiB |    70.55 B | SYCL       |  60 |           tg128 |          4.04 ± 0.01 |
| llama 70B Q2_K - Medium        |  24.56 GiB |    70.55 B | SYCL       | 999 |           pp512 |        111.73 ± 0.12 |
| llama 70B Q2_K - Medium        |  24.56 GiB |    70.55 B | SYCL       | 999 |           tg128 |          5.63 ± 0.01 |
| llama 70B IQ3_XS - 3.3 bpw     |  27.29 GiB |    70.55 B | SYCL       | 999 |           pp512 |         91.40 ± 0.21 |
| llama 70B IQ3_XS - 3.3 bpw     |  27.29 GiB |    70.55 B | SYCL       | 999 |           tg128 |          4.16 ± 0.00 |

build: 845282461 (9739)
```

---

### Additional Models (2026-07-09, build b9739)

15 more open-weight models, run with the same command (`-p 512 -n 128`, quant/offload noted per row). Two exceed the 32GB VRAM budget and use `--n-cpu-moe N` to offload N expert tensors to CPU instead of `-ngl`; both are multi-shard GGUFs (llama.cpp loads the trailing shards automatically from the first filename).

| Model | Type | Quant | Size | ngl / offload | Prompt (t/s) | Generation (t/s) | VRAM | Date |
|---|---|---|---|---|---|---|---|---|
| Qwen3 8B | Dense | Q4_K_M | 4.68 GiB | 999 | 1036.62 ± 4.12 | 81.79 ± 0.14 | 5.8 GiB | 2026-07-09 |
| Nemotron Nano 9B v2 | Dense | Q4_K_M | 6.07 GiB | 999 | 676.38 ± 0.41 | 22.14 ± 0.10 | 7.4 GiB | 2026-07-09 |
| Gemma 3 12B it | Dense | Q4_K_M | 6.79 GiB | 999 | 672.84 ± 1.15 | 50.80 ± 0.17 | 8.9 GiB | 2026-07-09 |
| DeepSeek-R1-Distill-Qwen 14B | Dense | Q4_K_M | 8.37 GiB | 999 | 497.29 ± 0.72 | 47.50 ± 0.11 | 9.6 GiB | 2026-07-09 |
| Qwen3 14B | Dense | Q4_K_M | 8.38 GiB | 999 | 570.98 ± 0.78 | 49.21 ± 0.10 | 9.7 GiB | 2026-07-09 |
| Phi-4 14B | Dense | Q4_K_M | 8.43 GiB | 999 | 545.52 ± 1.71 | 52.41 ± 0.08 | 10.0 GiB | 2026-07-09 |
| gpt-oss 20B | MoE | MXFP4 | 11.27 GiB | 999 | 861.55 ± 10.50 | 50.38 ± 0.04 | 11.5 GiB | 2026-07-09 |
| Mistral Small 3.2 24B | Dense | Q4_K_M | 13.34 GiB | 999 | 366.67 ± 0.28 | 32.89 ± 0.10 | 15.0 GiB | 2026-07-09 |
| Gemma 3 27B it | Dense | Q4_K_M | 15.40 GiB | 999 | 291.04 ± 0.50 | 26.18 ± 0.05 | 18.1 GiB | 2026-07-09 |
| Qwen3 30B-A3B Instruct | MoE | Q4_K_M | 17.35 GiB | 999 | 1187.50 ± 9.41 | 92.95 ± 1.16 | 18.4 GiB | 2026-07-09 |
| GLM-4 32B (0414) | Dense | Q4_K_M | 18.32 GiB | 999 | 253.69 ± 0.58 | 24.20 ± 0.03 | 20.4 GiB | 2026-07-09 |
| Qwen3 32B | Dense | Q4_K_M | 18.40 GiB | 999 | 243.74 ± 0.47 | 23.47 ± 0.06 | 20.0 GiB | 2026-07-09 |
| LLM-jp-4 32B-A3B thinking | MoE | Q4_K_M | 19.93 GiB | 999 | 946.68 ± 1.31 | 80.15 ± 0.15 | 20.6 GiB | 2026-07-09 |
| gpt-oss 120B | MoE | MXFP4 | 59.02 GiB | `--n-cpu-moe 22` | 136.42 ± 25.39 | 27.69 ± 0.16 | 24.7 GiB | 2026-07-09 |
| GLM-4.5-Air | MoE | Q4_K_M | 67.96 GiB | `--n-cpu-moe 31` | 85.37 ± 11.65 | 14.36 ± 0.26 | 26.4 GiB | 2026-07-09 |

Raw output:
```
| model                            |       size |     params | backend | ngl |  test | t/s              |
| --------------------------------- | ---------: | ---------: | ------- | --: | ----: | ----------------: |
| qwen3 8B Q4_K - Medium             |   4.68 GiB |    8.19 B  | SYCL    | 999 | pp512 | 1036.62 ± 4.12    |
| qwen3 8B Q4_K - Medium             |   4.68 GiB |    8.19 B  | SYCL    | 999 | tg128 |   81.79 ± 0.14    |
| nemotron_h 9B Q4_K - Medium        |   6.07 GiB |    8.89 B  | SYCL    | 999 | pp512 |  676.38 ± 0.41    |
| nemotron_h 9B Q4_K - Medium        |   6.07 GiB |    8.89 B  | SYCL    | 999 | tg128 |   22.14 ± 0.10    |
| gemma3 12B Q4_K - Medium           |   6.79 GiB |   11.77 B  | SYCL    | 999 | pp512 |  672.84 ± 1.15    |
| gemma3 12B Q4_K - Medium           |   6.79 GiB |   11.77 B  | SYCL    | 999 | tg128 |   50.80 ± 0.17    |
| qwen2 14B Q4_K - Medium            |   8.37 GiB |   14.77 B  | SYCL    | 999 | pp512 |  497.29 ± 0.72    |
| qwen2 14B Q4_K - Medium            |   8.37 GiB |   14.77 B  | SYCL    | 999 | tg128 |   47.50 ± 0.11    |
| qwen3 14B Q4_K - Medium            |   8.38 GiB |   14.77 B  | SYCL    | 999 | pp512 |  570.98 ± 0.78    |
| qwen3 14B Q4_K - Medium            |   8.38 GiB |   14.77 B  | SYCL    | 999 | tg128 |   49.21 ± 0.10    |
| phi3 14B Q4_K - Medium             |   8.43 GiB |   14.66 B  | SYCL    | 999 | pp512 |  545.52 ± 1.71    |
| phi3 14B Q4_K - Medium             |   8.43 GiB |   14.66 B  | SYCL    | 999 | tg128 |   52.41 ± 0.08    |
| gpt-oss 20B MXFP4 MoE              |  11.27 GiB |   20.91 B  | SYCL    | 999 | pp512 |  861.55 ± 10.50   |
| gpt-oss 20B MXFP4 MoE              |  11.27 GiB |   20.91 B  | SYCL    | 999 | tg128 |   50.38 ± 0.04    |
| llama 13B Q4_K - Medium            |  13.34 GiB |   23.57 B  | SYCL    | 999 | pp512 |  366.67 ± 0.28    |
| llama 13B Q4_K - Medium            |  13.34 GiB |   23.57 B  | SYCL    | 999 | tg128 |   32.89 ± 0.10    |
| gemma3 27B Q4_K - Medium           |  15.40 GiB |   27.01 B  | SYCL    | 999 | pp512 |  291.04 ± 0.50    |
| gemma3 27B Q4_K - Medium           |  15.40 GiB |   27.01 B  | SYCL    | 999 | tg128 |   26.18 ± 0.05    |
| qwen3moe 30B.A3B Q4_K - Medium     |  17.35 GiB |   30.53 B  | SYCL    | 999 | pp512 | 1187.50 ± 9.41    |
| qwen3moe 30B.A3B Q4_K - Medium     |  17.35 GiB |   30.53 B  | SYCL    | 999 | tg128 |   92.95 ± 1.16    |
| glm4 32B Q4_K - Medium             |  18.32 GiB |   32.57 B  | SYCL    | 999 | pp512 |  253.69 ± 0.58    |
| glm4 32B Q4_K - Medium             |  18.32 GiB |   32.57 B  | SYCL    | 999 | tg128 |   24.20 ± 0.03    |
| qwen3 32B Q4_K - Medium            |  18.40 GiB |   32.76 B  | SYCL    | 999 | pp512 |  243.74 ± 0.47    |
| qwen3 32B Q4_K - Medium            |  18.40 GiB |   32.76 B  | SYCL    | 999 | tg128 |   23.47 ± 0.06    |
| qwen3moe 32B.A3B Q4_K - Medium     |  19.93 GiB |   32.14 B  | SYCL    | 999 | pp512 |  946.68 ± 1.31    |
| qwen3moe 32B.A3B Q4_K - Medium     |  19.93 GiB |   32.14 B  | SYCL    | 999 | tg128 |   80.15 ± 0.15    |
| gpt-oss 120B MXFP4 MoE             |  59.02 GiB |  116.83 B  | SYCL    | 999 | pp512 |  136.42 ± 25.39   |
| gpt-oss 120B MXFP4 MoE             |  59.02 GiB |  116.83 B  | SYCL    | 999 | tg128 |   27.69 ± 0.16    |
| glm4moe 106B.A12B Q4_K - Medium    |  67.96 GiB |  110.47 B  | SYCL    | 999 | pp512 |   85.37 ± 11.65   |
| glm4moe 106B.A12B Q4_K - Medium    |  67.96 GiB |  110.47 B  | SYCL    | 999 | tg128 |   14.36 ± 0.26    |

build: 845282461 (9739)
```

## Notes

- The Arc Pro B70's 32GB VRAM allows running Q8_0 quantization on 8B models without VRAM pressure — most consumer GPUs (8–16GB) cannot do this
- SYCL backend confirmed working via `clinfo` device ID `0xe223` (B70 PCI device ID)
- Ollama's official Linux build does **not** use GPU acceleration for Arc GPUs — use llama.cpp SYCL directly for GPU inference
