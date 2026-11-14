LOCAL_PATH := device/vivo/PD2430

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Virtual A/B
AB_OTA_UPDATER := true
TARGET_IS_VAB := true
ENABLE_VIRTUAL_AB := true
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

PRODUCT_COPY_FILES += \
    $(foreach d,first_stage_ramdisk,$(call find-copy-subdir-files,*,$(LOCAL_PATH)/recovery/root/$(d),vendor_ramdisk/$(d)))

PRODUCT_PACKAGES += \
    update_engine \
    update_verifier \
    update_engine_sideload \
    otapreopt_script \
    cppreopts.sh

PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl \
    android.hardware.boot@1.2-service \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

# MTK 专属（minimal manifest 里没有就留空，编到报错再开）
# PRODUCT_PACKAGES += bootctrl.mt6989 create_pl_dev
