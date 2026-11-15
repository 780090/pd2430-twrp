#!/usr/bin/env python3
"""Skyward ui.rs 的 MTK/vivo 背光补丁（构建时应用）"""
p = "crates/skyward/src/ui.rs"
t = open(p).read()

# 1) 背光目录：/sys/class/backlight 为空时回退到 MTK 的 lcd-backlight
old = '''        let dir = dirs
            .iter()
            .find(|d| d.file_name().is_some_and(|n| n == "panel0-backlight"))
            .or(dirs.first())
            .ok_or_else(|| anyhow!("no backlight device"))?
            .clone();'''
new = '''        let dir = dirs
            .iter()
            .find(|d| d.file_name().is_some_and(|n| n == "panel0-backlight"))
            .or(dirs.first())
            .cloned()
            .unwrap_or_else(|| PathBuf::from("/sys/class/leds/lcd-backlight"));'''
assert old in t, "anchor1: 背光目录代码块未找到"
t = t.replace(old, new)

# 2) normal_max: 没有 msm_drm（非骁龙）直接用背光自身最大值
old2 = '''fn normal_max(max: u32) -> Result<u32> {
    let param = "/sys/module/msm_drm/parameters/dsi_display0";'''
new2 = '''fn normal_max(max: u32) -> Result<u32> {
    if !Path::new("/sys/module/msm_drm").exists() {
        return Ok(max);
    }
    let param = "/sys/module/msm_drm/parameters/dsi_display0";'''
assert old2 in t, "anchor2: normal_max 代码块未找到"
t = t.replace(old2, new2)

open(p, "w").write(t)
print("ui.rs patched: MTK backlight fallback + no-msm-drm normal_max")
