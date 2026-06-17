# Roofline Analysis — Arc Pro B70 LLM Inference

This document analyzes the benchmark results through the lens of the roofline model, demonstrating why prompt processing and token generation scale so differently with quantization.

---

## Arc Pro B70 Hardware Limits

| Metric | Value |
|---|---|
| Peak compute (FP16) | ~19 TFLOPS |
| Memory bandwidth | ~456 GB/s |
| VRAM | 32 GB GDDR6 |
| **Ridge point** | **~41.7 FLOP/byte** |

The ridge point is the arithmetic intensity at which the GPU transitions from memory-bound to compute-bound:

\[ I_{ridge} = \frac{\text{Peak FLOPS}}{\text{Memory Bandwidth}} = \frac{19 \times 10^{12}}{456 \times 10^9} \approx 41.7 \text{ FLOP/byte} \]

Operations above this threshold are compute-bound (more FLOPS = faster). Operations below are memory-bound (more bandwidth = faster).

---

## Two Phases of Inference

LLM inference has two fundamentally different compute phases with very different arithmetic intensities.

### Prefill (Prompt Processing)

Processes all input tokens simultaneously as a **matrix × matrix** multiplication.

For a batch of `T` tokens and weight matrix of size `[d_model, d_ff]`:
- FLOPS: `O(T × d_model × d_ff)` — scales with batch size
- Memory reads: `O(d_model × d_ff)` — weights read once regardless of T

As T grows, arithmetic intensity grows linearly. At T=512 (our benchmark), intensity is well above the ridge point — **compute-bound**.

### Generation (Token Generation)

Generates one token at a time as a **matrix × vector** multiplication.

For a single token:
- FLOPS: `O(1 × d_model × d_ff)` — T=1, fixed
- Memory reads: `O(d_model × d_ff)` — same weights, read every single token

Arithmetic intensity is essentially fixed at ~1–5 FLOP/byte regardless of model size — **always memory-bound**, always far left of the ridge point.

---

## Roofline Prediction vs Actual Results

### Generation Speed Prediction

Since generation is memory-bound, throughput scales inversely with model size in bytes. Using Q4_K_M as the baseline:

| Quant | Size (GiB) | Size ratio vs Q4_K_M | Predicted gen (t/s) | Actual gen (t/s) | Error |
|---|---|---|---|---|---|
| Q4_K_M | 4.58 | 1.00× | 88.49 (baseline) | 88.49 | — |
| Q5_K_M | 5.33 | 1.164× | 88.49 / 1.164 = **76.0** | **78.06** | +2.7% |
| Q8_0 | 7.95 | 1.737× | 88.49 / 1.737 = **50.9** | **56.01** | +10.0% |

The Q5_K_M prediction (76.0 vs actual 78.1) is within 2.7% — close to the naive roofline model's prediction limit.

The Q8_0 prediction is 10% low. The likely cause: **caching effects**. Q8_0 weights have higher regularity (uniform 8-bit values vs mixed-precision K-quants), which may allow the GPU's L2 cache to be more effective, reducing effective memory traffic below what the raw model size implies.

### Prompt Speed Prediction

Since prefill is compute-bound, it should be nearly **independent of quantization**:

| Quant | Predicted prompt (t/s) | Actual prompt (t/s) | Delta |
|---|---|---|---|
| Q4_K_M | ~1068 (baseline) | 1068.94 | — |
| Q5_K_M | ~1068 | 1058.98 | -0.9% |
| Q8_0 | ~1068 | 1053.28 | -1.5% |

All within 1.5% of each other — consistent with compute-bound behavior. The small decline at Q8_0 is likely due to dequantization overhead being slightly higher for 8-bit vs 4-bit on this architecture.

---

## Key Takeaways

1. **Quantization is a memory bandwidth optimization**, not a compute optimization. It helps generation dramatically and prefill negligibly.

2. **The B70's 32GB VRAM** means you can choose Q8_0 (near-lossless quality) on 8B models without any VRAM pressure — most 8–16GB GPUs cannot do this at all.

3. **The roofline model predicts generation scaling within ~3%** for K-quants. Deviations for uniform quants suggest cache behavior matters.

4. **To improve generation speed**, you need more memory bandwidth — not more FLOPS. This is why HBM (H100: 3.35 TB/s) improves generation ~7× over the B70 (456 GB/s) despite only ~3× more raw FLOPS.

---

## Further Reading

- [Roofline Model — Williams et al. 2009](https://dl.acm.org/doi/10.1145/1498765.1498785)
- [Making Deep Learning Go Brrrr — Horace He](https://horace.io/brrr_intro.html) — accessible roofline explainer
- [llama.cpp quantization formats](https://github.com/ggerganov/llama.cpp/blob/master/docs/quantization.md)
