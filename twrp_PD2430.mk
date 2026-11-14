# X100(PD2309) 同款继承链：aosp_base 提供 recovery/init/adbd 等根文件系统包
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/vivo/PD2430/device.mk)

PRODUCT_DEVICE := PD2430
PRODUCT_NAME := twrp_PD2430
PRODUCT_BRAND := vivo
PRODUCT_MODEL := vivo S20 Pro
PRODUCT_MANUFACTURER := vivo
