# PD2430 TWRP CI（扁平目录版）

手机上传不用建目录：所有文件都在仓库根目录，workflow 里的「组装 device tree」一步会自动
拼成 `device/vivo/PD2430/` 再编译。

## 需要上传的文件

- `.github/workflows/build.yml`（网页里用 Create new file 建，路径照抄）
- `BoardConfig.mk` `device.mk` `AndroidProducts.mk` `twrp_PD2430.mk` `system.prop`
- `recovery.fstab` `fstab.mt6989`
- `init.recovery.mt6989.rc` `init.recovery.usb.rc` `loadmods.sh`
- `vendor-rec.tar.gz`（stock vendor_boot 的 286 个 .ko + modules.* + 4 个 rc）
- `Image.gz`（37MB，stock boot 内核）`dtb.img`（= stock vendor_boot 的 dtb 段，DTBO 组合镜像，不是 boot 里的 DTB）

## 跑

Actions → build → Run workflow。产物 `out/vendor_boot.img.gz` 由 CI 自己 push 回本仓库。
下载后解压，和 stock `vendor_boot_a.img` 一起跑 `check_vendorboot.py` 核对结构再刷。

## 关键点（别改错）

- 必须继承 `base.mk`：`base_vendor.mk` 里的 `PRODUCT_PACKAGES += recovery` 是 TWRP
  二进制进 ramdisk 的唯一入口，少了它产物就是几百 KB 的空壳。
- `dtb.img` 必须是 vendor_boot 的 DTBO（magic `d7b7ab1e`）；boot 里的 DTB
  （`d00dfeed`）是给正常启动用的，放进来会黑屏。
- 模块清单用 stock 的 `modules.load.recovery`，`loadmods.sh` 只做补充加载
  （init 自己会先加载 `modules.load`）。
