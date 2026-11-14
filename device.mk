LOCAL_PATH := device/vivo/PD2430

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Virtual A/B
AB_OTA_UPDATER := true
TARGET_IS_VAB := true
ENABLE_VIRTUAL_AB := true
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# fstab + 内核模块进 vendor ramdisk（first_stage 用），recovery root 的 lib 也一起
PRODUCT_COPY_FILES += \
    $(foreach d,first_stage_ramdisk lib,$(call find-copy-subdir-files,*,$(LOCAL_PATH)/recovery/root/$(d),vendor_ramdisk/$(d)))

# Update Engine & Update Verifier
PRODUCT_PACKAGES += \
    update_engine \
    update_verifier \
    update_engine_sideload

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

PRODUCT_PACKAGES += \
    otapreopt_script \
    cppreopts.sh

# Boot control HAL（minimal manifest 缺 MTK 源时被 ALLOW_MISSING_DEPENDENCIES 跳过，
# fastbootd 的 boot HAL 由 stock ramdisk 里的 boot-service.mtk_recovery 顶上）
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl \
    android.hardware.boot@1.2-impl.recovery \
    android.hardware.boot@1.2-service

PRODUCT_PACKAGES_DEBUG += \
    bootctrl

PRODUCT_PACKAGES += \
    bootctrl.mt6989 \
    bootctrl.mt6989.recovery

PRODUCT_PACKAGES += \
    create_pl_dev \
    create_pl_dev.recovery

# Health HAL
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# Soong
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd
