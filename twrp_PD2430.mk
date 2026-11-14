# 继承顺序照抄 remb(K60E) 可用树：base.mk 提供 recovery/init/adbd/toybox 等
# 根文件系统包（base_vendor.mk 里有 PRODUCT_PACKAGES += recovery），
# 没有它 recovery 二进制根本不会进 vendor_boot，ramdisk 就是空壳。
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
# 本机 boot_a 无 ramdisk（init 在 vendor_boot 的 vendor ramdisk 里）→ 必须声明
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/vivo/PD2430/device.mk)

PRODUCT_DEVICE := PD2430
PRODUCT_NAME := twrp_PD2430
PRODUCT_BRAND := vivo
PRODUCT_MODEL := vivo S20 Pro
PRODUCT_MANUFACTURER := vivo
