#!/usr/bin/env python3
"""把 xaga 天玑移植的背光方案完整搬进 extra 版 ui.rs（构建时应用）"""
import re

def patch(path, subs):
    t = open(path).read()
    for old, new, tag in subs:
        assert old in t, f"{path}: 锚点缺失 [{tag}]"
        t = t.replace(old, new)
    open(path, "w").write(t)
    print(f"{path} patched ({len(subs)} 处)")

# ---- ui.rs ----
ui = "crates/skyward/src/ui.rs"
subs_ui = []

old_open = '''impl Backlight {
    pub(crate) fn open() -> Result<Self> {
        let mut dirs: Vec<PathBuf> = fs::read_dir("/sys/class/backlight")
            .context("read /sys/class/backlight")?
            .map(|e| e.map(|e| e.path()))
            .collect::<std::io::Result<_>>()?;
        dirs.sort();
        // Qualcomm panels expose panel0-backlight; take it when present.
        let dir = dirs
            .iter()
            .find(|d| d.file_name().is_some_and(|n| n == "panel0-backlight"))
            .or(dirs.first())
            .ok_or_else(|| anyhow!("no backlight device"))?
            .clone();
        let read = |name: &str| -> Result<u32> {
            fs::read_to_string(dir.join(name))
                .with_context(|| format!("read {}/{name}", dir.display()))?
                .trim()
                .parse()
                .with_context(|| format!("parse {name}"))
        };
        let top = normal_max(read("max_brightness")?)?;
        let level = read("brightness")?;
        Ok(Backlight { path: dir.join("brightness"), top, level })
    }'''
new_open = '''impl Backlight {
    pub(crate) fn open() -> Result<Option<Self>> {
        let dirs = |folder: &str| -> Result<Vec<PathBuf>> {
            match fs::read_dir(folder) {
                Ok(listing) => {
                    let mut paths = listing.map(|e| e.map(|e| e.path())).collect::<std::io::Result<Vec<_>>>()?;
                    paths.sort();
                    Ok(paths)
                }
                Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(Vec::new()),
                Err(e) => Err(e).with_context(|| format!("read {folder}")),
            }
        };
        let class = dirs("/sys/class/backlight")?;
        // Qualcomm panels expose panel0-backlight; take it when present.
        let dir = class
            .iter()
            .find(|d| d.file_name().is_some_and(|n| n == "panel0-backlight"))
            .cloned()
            .or_else(|| class.first().cloned())
            .or_else(|| {
                // MediaTek's panel backlight is an LED named lcd-backlight.
                dirs("/sys/class/leds").ok().and_then(|leds| {
                    leds.into_iter().find(|d| d.file_name().is_some_and(|n| n.to_string_lossy().contains("backlight")))
                })
            });
        let Some(dir) = dir else {
            eprintln!("no backlight device; the panel keeps the light the bootloader gave it");
            return Ok(None);
        };
        let read = |name: &str| -> Result<u32> {
            fs::read_to_string(dir.join(name))
                .with_context(|| format!("read {}/{name}", dir.display()))?
                .trim()
                .parse()
                .with_context(|| format!("parse {name}"))
        };
        let max = read("max_brightness").unwrap_or(255);
        let top = normal_max(max).unwrap_or(max);
        let level = read("brightness")?;
        Ok(Some(Backlight { path: dir.join("brightness"), top, level }))
    }'''
subs_ui.append((old_open, new_open, "open"))

subs_ui.append(("    backlight: Backlight,", "    backlight: Option<Backlight>,", "field"))
subs_ui.append((
    "        if self.backlight.level == 0 && panel.is_some() {",
    "        if self.backlight.as_ref().is_some_and(|b| b.level == 0) && panel.is_some() {",
    "level-check"))
subs_ui.append((
    "        self.backlight.show(panel)?;",
    "        if let Some(light) = &mut self.backlight { light.show(panel)?; }",
    "show"))

patch(ui, subs_ui)

# ---- supervise.rs ----
subs_sv = [(
    "    let mut light = Backlight::open().ok();",
    "    let mut light = Backlight::open().ok().flatten();",
    "supervise-light")]
patch("crates/skyward/src/supervise.rs", subs_sv)
