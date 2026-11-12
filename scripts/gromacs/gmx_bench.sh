#!/bin/bash
# GROMACS MPI-NAT benchmark runner for the Arc Pro B70.
# usage: gmx_bench.sh <bench> <gpu|cpu> <nsteps> <repeats>
#   bench: benchMEM | benchRIB | benchPEP   (expects ~/gromacs/bench/<bench>.tpr)
# Writes ~/gromacs/results/<bench>_<mode>_rN.log and appends a row to results.tsv:
#   bench mode rep ns_per_day hours_per_ns wall_s b70_avg_W energy_kJ gpu_name
set -uo pipefail
B=$1; MODE=$2; NSTEPS=$3; REPS=$4
set +u; source /opt/intel/oneapi/setvars.sh --force >/dev/null 2>&1; set -u
GMX=~/opt/gromacs-2026.4-sycl/bin/gmx
export ONEAPI_DEVICE_SELECTOR=level_zero:0 SYCL_CACHE_PERSISTENT=1
OUT=~/gromacs/results; mkdir -p "$OUT"
TSV=$OUT/results.tsv
[ -f "$TSV" ] || printf "bench\tmode\trep\tns_per_day\thours_per_ns\twall_s\tb70_avg_W\tenergy_kJ\tgpu\tflags\n" > "$TSV"
# B70 = the xe card at PCI 0000:03:00.0; energy1 is the card-level counter (microjoules).
HW=$(ls -d /sys/bus/pci/devices/0000:03:00.0/hwmon/hwmon* | head -1)
energy() { cat "$HW/energy1_input"; }
case $MODE in
  gpu) FLAGS="-nb gpu -pme gpu -bonded gpu -update auto -ntmpi 1 -ntomp 8 -pin on -pinstride 2" ;;
  cpu) FLAGS="-nb cpu -pme cpu -bonded cpu -update cpu" ;;
esac
W=$(mktemp -d); cd "$W"
for r in $(seq 1 "$REPS"); do
  LOG=$OUT/${B}_${MODE}_r$r.log
  e0=$(energy); t0=$(date +%s.%N)
  $GMX mdrun -s ~/gromacs/bench/$B.tpr $FLAGS -nsteps "$NSTEPS" -resethway -notunepme -noconfout \
       -g "$LOG" >"$OUT/${B}_${MODE}_r$r.out" 2>&1
  rc=$?
  t1=$(date +%s.%N); e1=$(energy)
  wall=$(echo "$t1 - $t0" | bc -l)
  watts=$(echo "($e1 - $e0) / 1000000 / $wall" | bc -l)
  kj=$(echo "($e1 - $e0) / 1000000000" | bc -l)
  perf=$(awk '/^Performance:/{print $2, $3}' "$LOG")
  gpu=$(grep -m1 -oE "#0: name: [^,]+" "$LOG" | sed 's/#0: name: //')
  [ $rc -ne 0 ] && perf="FAILED rc=$rc"
  printf "%s\t%s\t%d\t%s\t%s\t%.1f\t%.1f\t%.2f\t%s\t%s\n" "$B" "$MODE" "$r" \
    "$(echo $perf | cut -d' ' -f1)" "$(echo $perf | cut -d' ' -f2)" "$wall" "$watts" "$kj" "$gpu" "$FLAGS" | tee -a "$TSV"
done
rm -rf "$W"
