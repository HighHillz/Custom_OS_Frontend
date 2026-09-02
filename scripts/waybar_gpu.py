#!/usr/bin/env python3
"""
waybar_gpu.py — NVIDIA GPU + VRAM usage for Waybar custom module.
Outputs JSON: { text, tooltip, class }
"""
import json
import subprocess

def get_gpu_stats():
    try:
        raw = subprocess.check_output(
            [
                "nvidia-smi",
                "--query-gpu=utilization.gpu,memory.used,memory.total",
                "--format=csv,noheader,nounits",
            ],
            stderr=subprocess.DEVNULL,
            timeout=2,
        ).decode().strip()
        gpu_pct, vram_used, vram_total = [x.strip() for x in raw.split(",")]
        gpu_pct   = int(gpu_pct)
        vram_used  = int(vram_used)
        vram_total = int(vram_total)
        vram_pct  = round(vram_used / vram_total * 100)
        return gpu_pct, vram_pct, vram_used, vram_total
    except Exception:
        return None, None, None, None


gpu_pct, vram_pct, vram_used, vram_total = get_gpu_stats()

if gpu_pct is None:
    result = {
        "text": "󰒇 N/A",
        "tooltip": "GPU: unavailable",
        "class": "gpu-unavailable",
    }
else:
    # 󰒇 = GPU chip icon (nf-md-expansion_card),  = VRAM (nf-md-memory)
    text = f"󰒇 {gpu_pct}%  󰍛 {vram_pct}%"

    # State class for CSS colouring
    css_class = ""
    if gpu_pct >= 85 or vram_pct >= 85:
        css_class = "critical"
    elif gpu_pct >= 70 or vram_pct >= 70:
        css_class = "warning"

    tooltip = (
        f"GPU:  {gpu_pct}%\n"
        f"VRAM: {vram_used} MiB / {vram_total} MiB  ({vram_pct}%)"
    )

    result = {"text": text, "tooltip": tooltip, "class": css_class}

print(json.dumps(result, ensure_ascii=False))
