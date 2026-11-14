# PD2430 TWRP CI（扁平目录版 · twrp-14.0）

vivo S20 Pro (PD2430 / mt6989 / OriginOS6) TWRP，配方照搬 X100(PD2309) 可用树：
nebrassy twrp-14 + `lunch twrp_PD2430-ap2a-eng` + `make vendorbootimage`。

## 仓库文件

- `.github/workflows/build.yml`（单行 JSON，workflow_dispatch）
- 树：`BoardConfig.mk` `device.mk` `twrp_PD2430.mk` `AndroidProducts.mk` `system.prop` `Android.mk` `Android.bp`
- ramdisk：`recovery.fstab` `fstab.mt6989` `twrp.flags` `manifest.xml`
- rc：`init.recovery.mt6989.rc`（主）`init.recovery.usb.rc` `init.recovery.trustonic.rc`
- `prepdecrypt.sh`（解密：挂 persist + crypto.ready）
- `vendor-rec.tar.gz`：stock vendor_boot 的 300 个 .ko + modules.{load,load.recovery,...} + 4 个 rc
- `vendor-trustonic.tar.gz`：本机 /vendor 提取的 trustonic 解密栈（兜底副本，主路径走真实 /vendor）
- `Image.gz` `dtb.img`（= stock vendor_boot 的 dtb 段，DTBO 组合镜像）

## 跑

Actions → build → Run workflow。产物 `out/vendor_boot.img.gz` 由 CI push 回仓库，
同时上传 Actions Artifacts（14 天）。下载后和 stock `vendor_boot_a.img` 一起跑
`check_vendorboot.py` 核对再刷。

## 解密原理（X100 同款）

`prepdecrypt.sh` 挂 /persist → `crypto.ready=1` → trustonic.rc 拉起 mobicore/
gatekeeper/keymint@3.0（服务定义来自真实 /vendor/etc/init/）→ TWRP 用 wrappedkey
方案解 /data。依赖 fstab 里 vendor 的 first_stage_mount 先挂好 /vendor。

## 分支

- `main`：twrp-14.0（解密版）
- `twrp-12.1`：12.1 无解密版（保底回滚）
