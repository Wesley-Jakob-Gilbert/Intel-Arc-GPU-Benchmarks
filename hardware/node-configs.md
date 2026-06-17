# Hardware Configurations

## Node 1 — Scout Node (Active)

| Component | Spec | Status |
|---|---|---|
| CPU | Intel Core i9-14900K | Purchased (EPP) |
| Motherboard | ASUS ROG Maximus Z790 Dark Hero | Purchased (EPP) |
| GPU | Intel Arc Pro B70 32GB GDDR6 | Purchased ($949) |
| RAM | Kingston FURY Beast 64GB DDR5-6000 (4×16GB) | Purchased (EPP) |
| CPU Cooler | ARCTIC Liquid Freezer III Pro 360 | Ordered |
| PSU | Seasonic PRIME TX-1600 Titanium 1600W | Ordered |
| Chassis | SilverStone RM44 4U Rackmount | Ordered |
| NVMe | WD Black SN850X 4TB | Ordered |
| OS | Ubuntu 26.04 LTS "Resolute Raccoon" | Installed |
| Location | PA basement (permanent) |  |

**PCIe note:** Z790 Dark Hero M.2_1 shares bandwidth with PCIe slot 2. With NVMe in M.2_1, slot 2 is disabled. Arc Pro B70 runs in slot 1 at PCIe 5.0 x8.

---

## Node 2 — Xeon Node (Planned, CPU purchased)

| Component | Spec | Status |
|---|---|---|
| CPU | Intel Xeon W9-658X (24C/48T, 128 PCIe 5.0 lanes) | Ordered (EPP $1,236) |
| Motherboard | ASUS Pro WS W890E-SAGE SE (W-800, EEB) | Ready to Order |
| GPU | Intel Arc B580 12GB ×3 (4th pending) | 3 Ordered ($210 each refurb) |
| RAM | DDR5 ECC RDIMM (phased purchase) | TBD |
| NVMe | WD Black SN850X 2TB | Ready to Order |
| Chassis | Fractal Design Define 7 XL (SSI-EEB) | Ready to Order |
| PSU | Seasonic PRIME TX-1600 (relocated from Node 1) | — |
| CPU Cooler | Noctua NH-D9 DX-4677 4U (LGA4710 native) | Ready to Order |
| OS | Ubuntu 26.04 LTS | Planned |
| Location | PA basement (permanent) | |

**Future GPU upgrade:** 2× RTX 5090 targeted for Q1 2027 when prices normalize.

---

## Cluster Configuration (Planned)

- Nodes connected via Tailscale VPN (current) → 100GbE switch (Phase 3)
- Head node: Scout Node (i9-14900K) running Slurm job scheduler
- Compute node: Xeon Node (W9-658X) for inference + simulation workloads
- Total pooled VRAM (with 4× B580): 32GB (B70) + 48GB (4× B580) = **80GB**
