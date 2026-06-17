# Intel Arc GPU Compute Stack — Ubuntu 26.04 LTS Setup Guide

Complete driver and oneAPI install guide for Intel Arc B-series GPUs on Ubuntu 26.04 LTS. Covers OpenCL, Level Zero, and oneAPI DPC++ required for llama.cpp SYCL inference.

This guide documents every error encountered during a real install — not just the happy path.

---

## Prerequisites

- Ubuntu 26.04 LTS (kernel 7.0.0+)
- Intel Arc B-series GPU (tested: Arc Pro B70)
- sudo access

---

## Step 1 — Add Intel GPU Repository

```bash
wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
  sudo gpg --dearmor -o /usr/share/keyrings/intel-graphics.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] \
  https://repositories.intel.com/gpu/ubuntu noble client" | \
  sudo tee /etc/apt/sources.list.d/intel-gpu-noble.list

sudo apt update
```

> **Note:** `arch=amd64` refers to 64-bit x86 architecture — not AMD hardware. This applies to Intel CPUs too.

---

## Step 2 — Install Compute Runtime (OpenCL + Level Zero)

```bash
sudo apt install -y \
  intel-opencl-icd \
  intel-level-zero-gpu \
  libze1 \
  libze-dev \
  libze-intel-gpu1
```

> **Known issue:** Conflict between `intel-level-zero-gpu` and `libze-intel-gpu1`. If you see a `trying to overwrite` error:
> ```bash
> sudo apt remove intel-level-zero-gpu
> sudo apt install -y libze-intel-gpu1
> ```

---

## Step 3 — Add Intel oneAPI Repository

```bash
wget -qO - https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
  sudo gpg --dearmor -o /usr/share/keyrings/oneapi-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] \
  https://apt.repos.intel.com/oneapi all main" | \
  sudo tee /etc/apt/sources.list.d/oneAPI.list

sudo apt update
```

---

## Step 4 — Install oneAPI Compiler and MKL

> **Note:** The package was renamed from `intel-oneapi-dpcpp-cpp` to `intel-oneapi-compiler-dpcpp-cpp` in recent releases.

```bash
sudo apt install -y \
  intel-oneapi-compiler-dpcpp-cpp \
  intel-oneapi-mkl \
  intel-oneapi-mkl-devel
```

---

## Step 5 — Add User to Render Group

Without this, OpenCL cannot access the GPU device even if drivers are installed correctly.

```bash
sudo usermod -aG render,video $USER
```

**Fully log out and back in** (not just a new terminal — group changes require a fresh session).

---

## Step 6 — Reboot and Verify

```bash
sudo reboot
```

After reconnecting:

```bash
# Verify compiler
source /opt/intel/oneapi/setvars.sh
icpx --version
# Expected: Intel(R) oneAPI DPC++/C++ Compiler 2026.x.x

# Verify GPU visible to OpenCL
sudo apt install clinfo
clinfo | grep "Device Name"
# Expected: Intel(R) Graphics [0xe223]  (B70 device ID)
#           Intel(R) Core(TM) i9-14900K  (CPU — normal)

# Verify GPU device node exists
ls /dev/dri/
# Expected: by-path  card0  renderD128

# Verify render group membership
groups
# Expected: ... render video ...
```

---

## Troubleshooting

**`clinfo` shows only CPU, not GPU:**
- Run `groups` — if `render` is missing, re-run Step 5 and fully log out/in

**`level-zero` / `level-zero-dev` not found:**
- Use `libze1` and `libze-dev` instead (package rename in newer Intel repos)

**`intel-oneapi-dpcpp-cpp` not found:**
- Use `intel-oneapi-compiler-dpcpp-cpp` (renamed in 2024+ releases)
- Confirm repo is added: `cat /etc/apt/sources.list.d/oneAPI.list`

**GPU physically detected but OpenCL empty:**
```bash
ls /etc/OpenCL/vendors/   # should contain intel.icd
sudo apt install --reinstall intel-opencl-icd
sudo ldconfig
```

---

## Software Versions (tested)

| Package | Version |
|---|---|
| intel-opencl-icd | 26.05.37020.3-1 |
| libze-intel-gpu1 | 26.05.37020.3-1 |
| intel-oneapi-compiler-dpcpp-cpp | 2026.0.0-947 |
| intel-oneapi-mkl | 2026.0.0-908 |
| OS | Ubuntu 26.04 LTS, kernel 7.0.0-22-generic |
