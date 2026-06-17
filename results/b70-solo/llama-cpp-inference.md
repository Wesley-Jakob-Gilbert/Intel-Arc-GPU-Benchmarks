# Arc Pro B70 — llama.cpp SYCL Inference Benchmarks

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
| llama.cpp | b9672-74ade5274 |
| Backend | SYCL (Intel oneAPI) |
| oneAPI compiler | 2026.0.0 |
| intel-opencl-icd | 26.05.37020.3-1 |
| libze-intel-gpu1 | 26.05.37020.3-1 |

## Benchmark Command

```bash
source /opt/intel/oneapi/setvars.sh
./build/bin/llama-bench -m <model.gguf> -ngl 999 -p 512 -n 128
```

- `-ngl 999` — offload all layers to GPU
- `-p 512` — 512 token prompt processing test
- `-n 128` — 128 token generation test

---

## Results

### Llama 3.1 8B Instruct

| Quant | Size | Prompt (t/s) | Generation (t/s) | Date |
|---|---|---|---|---|
| Q4_K_M | 4.58 GiB | 1068.94 ± 0.86 | 88.49 ± 0.10 | 2026-06-16 |

Raw output:
```
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | SYCL       | 999 |           pp512 |       1068.94 ± 0.86 |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | SYCL       | 999 |           tg128 |         88.49 ± 0.10 |

build: 74ade5274 (9672)
```

*Additional quantization levels (Q5_K_M, Q8_0) and larger models (70B) in progress.*

---

## Notes

- The Arc Pro B70's 32GB VRAM allows running Q8_0 quantization on 8B models without VRAM pressure — most consumer GPUs (8–16GB) cannot do this
- SYCL backend confirmed working via `clinfo` device ID `0xe223` (B70 PCI device ID)
- Ollama's official Linux build does **not** use GPU acceleration for Arc GPUs — use llama.cpp SYCL directly for GPU inference
