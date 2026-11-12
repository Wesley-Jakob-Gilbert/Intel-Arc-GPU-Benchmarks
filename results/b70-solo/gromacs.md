# Arc Pro B70 — GROMACS Molecular Dynamics (SYCL)

## Hardware

| Component | Spec |
|---|---|
| GPU | Intel Arc Pro B70 32GB GDDR6 |
| CPU | Intel Core i9-14900K (24C/32T) |
| RAM | 64GB DDR5-6000 |
| Motherboard | ASUS ROG Maximus Z790 Dark Hero |
| OS | Ubuntu 26.04 LTS (kernel 7.0.0-43-generic) |
| PCIe slot | x8 (PCIe 5.0) |

## Software

| Component | Version |
|---|---|
| GROMACS | 2026.4, SYCL backend (`-DGMX_GPU=SYCL -DGMX_SYCL=DPCPP`), single-rank, no MPI |
| Compiler | Intel oneAPI DPC++/C++ 2026.2.0 (icx/icpx), `-ffast-math` |
| FFT | Intel MKL 2026.0.2 (CPU and GPU) |
| CPU SIMD | AVX2_256 |
| GPU driver | Level Zero, driver version 1.14.37020 (device reported as `Intel(R) Graphics [0xe223]`, arch 20.2.0) |

Build script: [`scripts/gromacs/gromacs_build.sh`](../../scripts/gromacs/gromacs_build.sh).

## Benchmarks

The three standard [MPI-NAT GROMACS benchmarks](https://www.mpinat.mpg.de/grubmueller/bench) (Kutzner et al.):

| Benchmark | System | Atoms | Time step |
|---|---|---|---|
| benchMEM | Aquaporin membrane protein in a lipid bilayer | 81,743 | 2 fs |
| benchRIB | Ribosome in water | 2,037,824 | 4 fs |
| benchPEP | Peptides in water | 12,495,503 | 2 fs |

## Results

Mean of 3 back-to-back runs per cell; ns/day is the value GROMACS reports after the counter reset at half-way (`-resethway`). Per-run numbers are in [`raw/gromacs/results.tsv`](raw/gromacs/results.tsv).

| Benchmark | B70 (ns/day) | CPU only, i9-14900K (ns/day) | Speedup | B70 avg card power (W) |
|---|---|---|---|---|
| benchMEM (82k atoms) | 235.7 | 46.6 | 5.06x | 183 |
| benchRIB (2.0M atoms) | 11.08 | 2.70 | 4.10x | 172 |
| benchPEP (12.5M atoms) | 1.816 | 0.194 | 9.36x | 214 |

Run-to-run spread is under 1% for every GPU cell and under 3% for every CPU cell.

Notes:

- GPU speedup grows with system size. The B70 is least advantageous on the small membrane system, where the CPU keeps up better.
- Power is the card-level `energy1_input` counter of the xe hwmon device, averaged over the whole run (including start-up). It is not measured for the CPU, so no performance-per-watt comparison against the CPU is made here.
- 12.5M atoms (`benchPEP`) fits in the B70's 32GB; peak VRAM was not recorded.

## Configuration

GPU runs (`-update auto`):

```bash
gmx mdrun -s <bench>.tpr -nb gpu -pme gpu -bonded gpu -update auto \
  -ntmpi 1 -ntomp 8 -pin on -pinstride 2 \
  -nsteps <N> -resethway -notunepme -noconfout
```

CPU runs:

```bash
gmx mdrun -s <bench>.tpr -nb cpu -pme cpu -bonded cpu -update cpu \
  -nsteps <N> -resethway -notunepme -noconfout   # defaults to 32 thread-MPI ranks x 1 OpenMP thread
```

| Benchmark | `-nsteps` (GPU) | `-nsteps` (CPU) |
|---|---|---|
| benchMEM | 20000 | 10000 |
| benchRIB | 5000 | 2000 |
| benchPEP | 1000 | 300 |

- `-notunepme` is required: with PME auto-tuning on, `-resethway` aborts ("PME tuning was still active when attempting to reset mdrun counters"). Disabling tuning may leave some GPU performance on the table.
- `-update auto` put coordinate update and constraints on the GPU for `benchPEP` but on the CPU for `benchMEM` and `benchRIB` (see "PP task will update and constrain coordinates on ..." in each log). `benchMEM` cannot use update groups because of three or more consecutively coupled constraints.
- The runs are short (a few hundred to tens of thousands of steps), which is standard for these benchmarks but means start-up effects are not fully amortized.
- Single machine, single day (2026-11-12); no reruns on other driver versions.

## Reproducing

```bash
# 1. Build GROMACS with SYCL (see scripts/gromacs/gromacs_build.sh)
# 2. Download the benchmark inputs from https://www.mpinat.mpg.de/grubmueller/bench
#    (benchMEM.zip, benchRIB.zip, benchPEP.zip) and unzip the .tpr files into ~/gromacs/bench/
# 3. Run
scripts/gromacs/gmx_bench.sh benchMEM gpu 20000 3
scripts/gromacs/gmx_bench.sh benchMEM cpu 10000 3
scripts/gromacs/gmx_bench.sh benchRIB gpu 5000 3
scripts/gromacs/gmx_bench.sh benchRIB cpu 2000 3
scripts/gromacs/gmx_bench.sh benchPEP gpu 1000 3
scripts/gromacs/gmx_bench.sh benchPEP cpu 300 3
```

`gmx_bench.sh` writes one log per run and appends to `results.tsv`. It assumes the B70 is the xe card at PCI `0000:03:00.0` for the power counter and `ONEAPI_DEVICE_SELECTOR=level_zero:0` for the GPU; adjust both for other machines.
