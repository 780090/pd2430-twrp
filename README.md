# PD2430 TWRP CI（扁平目录版）

手机上传不用建目录：所有文件都在仓库根目录，workflow 里的「组装 device tree」一步会自动
拼成 `device/vivo/PD2430/` 再编译。

## 需要上传的文件

- `.github/workflows/build.yml`（网页里用 Create new file 建，路径照抄）
- `BoardConfig.mk` `device.mk` `AndroidProducts.mk` `twrp_PD2430.mk` `system.prop`
- `recovery.fstab` `fstab.mt6989`
- `Image`（37MB）`dtb.img`（451KB）
- `README.md`（这个，可选）

## 跑

Actions → build-twrp-PD2430 → Run workflow。产物 `vendor_boot.img` 在 Artifacts。
