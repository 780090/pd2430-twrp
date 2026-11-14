$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/vivo/PD2430/device.mk)

PRODUCT_DEVICE := PD2430
PRODUCT_NAME := twrp_PD2430
PRODUCT_BRAND := vivo
PRODUCT_MODEL := vivo S20 Pro
PRODUCT_MANUFACTURER := vivo
