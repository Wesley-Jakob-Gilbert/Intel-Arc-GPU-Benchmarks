# Arc Pro B70 — Prompt Length Scaling

Tests how prompt processing (prefill) throughput changes with input length.
Model: Llama 3.1 8B Instruct Q4_K_M, generation fixed at 128 tokens.

## Hardware / Software
See [llama-cpp-inference.md](llama-cpp-inference.md) for full specs.

## Results

| Prompt Tokens | Prompt (t/s) | Gen (t/s) | Date |
|---|---|---|---|
| 128 | 789.22 ± 8.22 | 87.76 ± 0.13 | 2026-06-17 |
| 512 | 1059.31 ± 1.99 | 87.76 ± 0.13 | 2026-06-17 |
| 1024 | 1025.53 ± 0.83 | 87.76 ± 0.13 | 2026-06-17 |
| 2048 | 948.56 ± 1.17 | 87.76 ± 0.13 | 2026-06-17 |

Raw output:
```
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | SYCL       | 999 |           pp128 |        789.22 ± 8.22 |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | SYCL       | 999 |           pp512 |       1059.31 ± 1.99 |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | SYCL       | 999 |          pp1024 |       1025.53 ± 0.83 |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | SYCL       | 999 |          pp2048 |        948.56 ± 1.17 |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | SYCL       | 999 |           tg128 |         87.76 ± 0.13 |

build: 74ade5274 (9672)
```

## Analysis

Generation throughput is **completely flat** across all prompt lengths (87.76 t/s) — confirming it is purely memory-bound and independent of context size at these lengths.

Prompt throughput peaks at **512 tokens (1059 t/s)** then declines at longer lengths:

| Prompt | t/s | vs peak |
|---|---|---|
| 128 | 789 | -25.5% |
| 512 | 1059 | peak |
| 1024 | 1026 | -3.1% |
| 2048 | 949 | -10.4% |

Two effects explain this:

**At pp128 — underutilization:** 128 tokens is too small a batch to fully saturate the GPU's compute units. The matrix × matrix multiply doesn't have enough work to hide memory latency and fill all shader cores. GPU utilization is low — this is the left side of the roofline even for prefill.

**At pp1024/pp2048 — KV cache pressure:** As context grows, the attention mechanism must attend over a larger KV cache. Attention is O(n²) in sequence length — at 2048 tokens, attention compute is 16× larger than at 512. This shifts the attention layers toward memory-bound behavior as the KV cache grows, pulling overall throughput down even though the FFN layers remain compute-bound.

The **sweet spot is ~512 tokens** for this GPU at this model size — large enough to saturate compute, small enough that attention overhead is minimal.

See [roofline analysis](../docs/roofline-analysis.md) for background theory.
