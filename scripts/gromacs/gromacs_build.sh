#!/bin/bash
# Build GROMACS with the SYCL (oneAPI DPC++) backend for the Arc Pro B70, into ~/opt.
# Downloads + configures immediately; compiles only after the Blender benchmark has finished,
# so the Blender scores are not disturbed.
set -eo pipefail
V=2026.4
SRC=~/gromacs
PREFIX=~/opt/gromacs-$V-sycl
LOG=$SRC/build-$V.log
mkdir -p "$SRC" ~/opt
cd "$SRC"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date +%T)] download"
[ -f gromacs-$V.tar.gz ] || wget -q https://ftp.gromacs.org/gromacs/gromacs-$V.tar.gz
[ -f regressiontests-$V.tar.gz ] || wget -q https://ftp.gromacs.org/regressiontests/regressiontests-$V.tar.gz
[ -d gromacs-$V ] || tar xf gromacs-$V.tar.gz
[ -d regressiontests-$V ] || tar xf regressiontests-$V.tar.gz

set +u; source /opt/intel/oneapi/setvars.sh --force >/dev/null; set -u
icpx --version | head -1
echo "[$(date +%T)] configure"
mkdir -p gromacs-$V/build-sycl && cd gromacs-$V/build-sycl
cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx \
  -DGMX_GPU=SYCL -DGMX_SYCL=DPCPP \
  -DGMX_FFT_LIBRARY=mkl -DGMX_GPU_FFT_LIBRARY=MKL \
  -DGMX_BUILD_OWN_FFTW=OFF -DGMX_MPI=OFF -DGMX_OPENMP=ON \
  -DREGRESSIONTEST_PATH="$SRC/regressiontests-$V" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" 2>&1 | tail -25

echo "[$(date +%T)] waiting for Blender benchmark to finish"
blender_busy() {   # the CPU run is last; done when its JSON is written and nothing is rendering
  ! compgen -G "$HOME/blender/results/b70_CPU_*.json" >/dev/null \
    || [ ! -s "$(ls -t ~/blender/results/b70_CPU_*.json | head -1)" ] \
    || pgrep -f "benchmark-launcher-cli|blender-5.1.1" >/dev/null
}
while blender_busy; do sleep 30; done
echo "[$(date +%T)] build"
ninja -j32 2>&1 | tail -5
ninja install 2>&1 | tail -2
echo "[$(date +%T)] regression tests"
export SYCL_CACHE_PERSISTENT=1
ninja check 2>&1 | tail -40 || echo "CHECK FAILED"
echo "[$(date +%T)] done"
"$PREFIX/bin/gmx" --version 2>&1 | grep -E "GROMACS version|GPU support|SYCL|FFT" | head -10
