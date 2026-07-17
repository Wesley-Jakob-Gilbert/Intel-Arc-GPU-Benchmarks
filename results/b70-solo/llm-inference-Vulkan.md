# Arc Pro B70 — LLM Inference Benchmarks (llama.cpp Vulkan)

## Hardware

| Component | Spec |
|---|---|
| GPU | Intel Arc Pro B70 32GB GDDR6 |
| CPU | Intel Core i9-14900K |
| RAM | 64GB DDR5-6000 |
| Motherboard | ASUS ROG Maximus Z790 Dark Hero |
| OS | Ubuntu 26.04 LTS (kernel 7.0.0-27-generic) |
| PCIe slot | x8 (PCIe 5.0) |

## Software

| Component | Version |
|---|---|
| llama.cpp | b9739-845282461 |
| Backend | Vulkan |
| Vulkan driver | Intel open-source Mesa driver (Mesa 26.0.3-1ubuntu1) |
| Vulkan API version | 1.4.335 |
| Matrix cores | KHR_coopmat |

## Benchmark Command

```bash
./build-vulkan/bin/llama-bench -m <model.gguf> -ngl 999 -p 512 -n 128
```

- `-ngl 999` — offload all layers to GPU (use lower value for models exceeding VRAM)
- `-p 512` — 512 token prompt processing test
- `-n 128` — 128 token generation test

---

## Results

### Llama 3.1 8B Instruct

| Type | Quant | Size | Prompt (t/s) | Generation (t/s) | Date |
|---|---|---|---|---|---|
| Dense | Q4_K_M | 4.58 GiB | 1980.11 ± 21.72 | 42.00 ± 0.09 | 2026-07-17 |
| Dense | Q5_K_M | 5.33 GiB | 1889.51 ± 21.77 | 38.86 ± 0.10 | 2026-07-17 |
| Dense | Q8_0 | 7.95 GiB | 2053.59 ± 35.90 | 20.31 ± 0.03 | 2026-07-17 |

Raw output:
```
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | Vulkan     | 999 |           pp512 |      1980.11 ± 21.72 |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | Vulkan     | 999 |           tg128 |         42.00 ± 0.09 |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | Vulkan     | 999 |           pp512 |      1889.51 ± 21.77 |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | Vulkan     | 999 |           tg128 |         38.86 ± 0.10 |
| llama 8B Q8_0                  |   7.95 GiB |     8.03 B | Vulkan     | 999 |           pp512 |      2053.59 ± 35.90 |
| llama 8B Q8_0                  |   7.95 GiB |     8.03 B | Vulkan     | 999 |           tg128 |         20.31 ± 0.03 |

build: 845282461 (9739)
```

---

### Llama 3.1 70B Instruct

| Type | Quant | Size | ngl | Mode | Prompt (t/s) | Generation (t/s) | Date |
|---|---|---|---|---|---|---|---|
| Dense | Q4_K_M | 39.59 GiB | 60/80 | Hybrid GPU+CPU | 145.86 ± 7.71 | 3.13 ± 0.02 | 2026-07-17 |
| Dense | Q2_K | 24.56 GiB | 999 | All GPU | 227.68 ± 1.06 | 3.39 ± 0.01 | 2026-07-17 |
| Dense | IQ3_XS | 27.29 GiB | 999 | All GPU | 227.65 ± 0.66 | 3.58 ± 0.00 | 2026-07-17 |

Raw output:
```
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 70B Q4_K - Medium        |  39.59 GiB |    70.55 B | Vulkan     |  60 |           pp512 |        145.86 ± 7.71 |
| llama 70B Q4_K - Medium        |  39.59 GiB |    70.55 B | Vulkan     |  60 |           tg128 |          3.13 ± 0.02 |
| llama 70B Q2_K - Medium        |  24.56 GiB |    70.55 B | Vulkan     | 999 |           pp512 |        227.68 ± 1.06 |
| llama 70B Q2_K - Medium        |  24.56 GiB |    70.55 B | Vulkan     | 999 |           tg128 |          3.39 ± 0.01 |
| llama 70B IQ3_XS - 3.3 bpw     |  27.29 GiB |    70.55 B | Vulkan     | 999 |           pp512 |        227.65 ± 0.66 |
| llama 70B IQ3_XS - 3.3 bpw     |  27.29 GiB |    70.55 B | Vulkan     | 999 |           tg128 |          3.58 ± 0.00 |

build: 845282461 (9739)
```

---

### Additional Models (2026-07-17, build b9739)

15 more open-weight models, run with the same command (`-p 512 -n 128`, quant/offload noted per row). Two exceed the 32GB VRAM budget and use `--n-cpu-moe N` to offload N expert tensors to CPU instead of `-ngl`; both are multi-shard GGUFs (llama.cpp loads the trailing shards automatically from the first filename).

| Model | Type | Quant | Size | ngl / offload | Prompt (t/s) | Generation (t/s) | Date |
|---|---|---|---|---|---|---|---|
| Qwen3 8B | Dense | Q4_K_M | 4.68 GiB | 999 | 1762.13 ± 14.88 | 39.53 ± 0.05 | 2026-07-17 |
| Nemotron Nano 9B v2 | Dense | Q4_K_M | 6.07 GiB | 999 | 1150.63 ± 1.66 | 19.19 ± 0.01 | 2026-07-17 |
| Gemma 3 12B it | Dense | Q4_K_M | 6.79 GiB | 999 | 1115.29 ± 2.63 | 23.49 ± 0.03 | 2026-07-17 |
| DeepSeek-R1-Distill-Qwen 14B | Dense | Q4_K_M | 8.37 GiB | 999 | 1018.55 ± 0.89 | 23.43 ± 0.01 | 2026-07-17 |
| Qwen3 14B | Dense | Q4_K_M | 8.38 GiB | 999 | 1033.86 ± 1.01 | 23.46 ± 0.02 | 2026-07-17 |
| Phi-4 14B | Dense | Q4_K_M | 8.43 GiB | 999 | 1084.64 ± 2.47 | 25.35 ± 0.04 | 2026-07-17 |
| gpt-oss 20B | MoE | MXFP4 | 11.27 GiB | 999 | 2118.57 ± 19.68 | 43.13 ± 0.08 | 2026-07-17 |
| Mistral Small 3.2 24B | Dense | Q4_K_M | 13.34 GiB | 999 | 709.25 ± 1.77 | 15.55 ± 0.04 | 2026-07-17 |
| Gemma 3 27B it | Dense | Q4_K_M | 15.40 GiB | 999 | 557.56 ± 0.74 | 12.22 ± 0.03 | 2026-07-17 |
| Qwen3 30B-A3B Instruct | MoE | Q4_K_M | 17.35 GiB | 999 | 1460.12 ± 23.91 | 62.37 ± 0.09 | 2026-07-17 |
| GLM-4 32B (0414) | Dense | Q4_K_M | 18.32 GiB | 999 | 322.56 ± 0.48 | 11.67 ± 0.01 | 2026-07-17 |
| Qwen3 32B | Dense | Q4_K_M | 18.40 GiB | 999 | 445.52 ± 1.01 | 11.58 ± 0.00 | 2026-07-17 |
| LLM-jp-4 32B-A3B thinking | MoE | Q4_K_M | 19.93 GiB | 999 | 1302.73 ± 13.33 | 66.28 ± 0.01 | 2026-07-17 |
| gpt-oss 120B | MoE | MXFP4 | 59.02 GiB | `--n-cpu-moe 22` | 69.28 ± 11.26 | 12.35 ± 2.72 | 2026-07-17 |
| GLM-4.5-Air | MoE | Q4_K_M | 67.96 GiB | `--n-cpu-moe 31` | 39.62 ± 4.33 | 6.12 ± 0.53 | 2026-07-17 |

Raw output:
```
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| qwen3 8B Q4_K - Medium          |   4.68 GiB |     8.19 B | Vulkan     | 999 |           pp512 |      1762.13 ± 14.88 |
| qwen3 8B Q4_K - Medium          |   4.68 GiB |     8.19 B | Vulkan     | 999 |           tg128 |         39.53 ± 0.05 |
| nemotron_h 9B Q4_K - Medium     |   6.07 GiB |     8.89 B | Vulkan     | 999 |           pp512 |       1150.63 ± 1.66 |
| nemotron_h 9B Q4_K - Medium     |   6.07 GiB |     8.89 B | Vulkan     | 999 |           tg128 |         19.19 ± 0.01 |
| gemma3 12B Q4_K - Medium        |   6.79 GiB |    11.77 B | Vulkan     | 999 |           pp512 |       1115.29 ± 2.63 |
| gemma3 12B Q4_K - Medium        |   6.79 GiB |    11.77 B | Vulkan     | 999 |           tg128 |         23.49 ± 0.03 |
| qwen2 14B Q4_K - Medium         |   8.37 GiB |    14.77 B | Vulkan     | 999 |           pp512 |       1018.55 ± 0.89 |
| qwen2 14B Q4_K - Medium         |   8.37 GiB |    14.77 B | Vulkan     | 999 |           tg128 |         23.43 ± 0.01 |
| qwen3 14B Q4_K - Medium         |   8.38 GiB |    14.77 B | Vulkan     | 999 |           pp512 |       1033.86 ± 1.01 |
| qwen3 14B Q4_K - Medium         |   8.38 GiB |    14.77 B | Vulkan     | 999 |           tg128 |         23.46 ± 0.02 |
| phi3 14B Q4_K - Medium          |   8.43 GiB |    14.66 B | Vulkan     | 999 |           pp512 |       1084.64 ± 2.47 |
| phi3 14B Q4_K - Medium          |   8.43 GiB |    14.66 B | Vulkan     | 999 |           tg128 |         25.35 ± 0.04 |
| gpt-oss 20B MXFP4 MoE           |  11.27 GiB |    20.91 B | Vulkan     | 999 |           pp512 |      2118.57 ± 19.68 |
| gpt-oss 20B MXFP4 MoE           |  11.27 GiB |    20.91 B | Vulkan     | 999 |           tg128 |         43.13 ± 0.08 |
| llama 13B Q4_K - Medium         |  13.34 GiB |    23.57 B | Vulkan     | 999 |           pp512 |        709.25 ± 1.77 |
| llama 13B Q4_K - Medium         |  13.34 GiB |    23.57 B | Vulkan     | 999 |           tg128 |         15.55 ± 0.04 |
| gemma3 27B Q4_K - Medium        |  15.40 GiB |    27.01 B | Vulkan     | 999 |           pp512 |        557.56 ± 0.74 |
| gemma3 27B Q4_K - Medium        |  15.40 GiB |    27.01 B | Vulkan     | 999 |           tg128 |         12.22 ± 0.03 |
| qwen3moe 30B.A3B Q4_K - Medium  |  17.35 GiB |    30.53 B | Vulkan     | 999 |           pp512 |      1460.12 ± 23.91 |
| qwen3moe 30B.A3B Q4_K - Medium  |  17.35 GiB |    30.53 B | Vulkan     | 999 |           tg128 |         62.37 ± 0.09 |
| glm4 32B Q4_K - Medium          |  18.32 GiB |    32.57 B | Vulkan     | 999 |           pp512 |        322.56 ± 0.48 |
| glm4 32B Q4_K - Medium          |  18.32 GiB |    32.57 B | Vulkan     | 999 |           tg128 |         11.67 ± 0.01 |
| qwen3 32B Q4_K - Medium         |  18.40 GiB |    32.76 B | Vulkan     | 999 |           pp512 |        445.52 ± 1.01 |
| qwen3 32B Q4_K - Medium         |  18.40 GiB |    32.76 B | Vulkan     | 999 |           tg128 |         11.58 ± 0.00 |
| qwen3moe 32B.A3B Q4_K - Medium  |  19.93 GiB |    32.14 B | Vulkan     | 999 |           pp512 |      1302.73 ± 13.33 |
| qwen3moe 32B.A3B Q4_K - Medium  |  19.93 GiB |    32.14 B | Vulkan     | 999 |           tg128 |         66.28 ± 0.01 |
| gpt-oss 120B MXFP4 MoE          |  59.02 GiB |   116.83 B | Vulkan     | 999 |           pp512 |         69.28 ± 11.26 |
| gpt-oss 120B MXFP4 MoE          |  59.02 GiB |   116.83 B | Vulkan     | 999 |           tg128 |          12.35 ± 2.72 |
| glm4moe 106B.A12B Q4_K - Medium |  67.96 GiB |   110.47 B | Vulkan     | 999 |           pp512 |         39.62 ± 4.33 |
| glm4moe 106B.A12B Q4_K - Medium |  67.96 GiB |   110.47 B | Vulkan     | 999 |           tg128 |          6.12 ± 0.53 |

build: 845282461 (9739)
```

Note: gpt-oss 120B and GLM-4.5-Air were run with `--n-cpu-moe 22`/`--n-cpu-moe 31` respectively (offloading MoE expert tensors to CPU), matching the SYCL results file's offload configuration for these two models.

## Notes

- Vulkan backend confirmed using the `KHR_coopmat` (Khronos cooperative matrix) extension path; device correctly classified as `INTEL_XE2` architecture (`minSubgroupSize = 16`).
- Mesa 26.0.3-1ubuntu1, Vulkan API 1.4.335.
