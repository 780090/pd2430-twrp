#!/usr/bin/env bash
# PD2430 TWRP 构建脚本（由 .github/workflows/build.yml 一行 JSON 调用）
set -eo pipefail

echo "== 腾磁盘"
sudo rm -rf /usr/share/dotnet /opt/ghc /usr/local/lib/android /usr/local/share/boost "${AGENT_TOOLSDIRECTORY:-/opt/hostedtoolcache}" || true
df -h /

echo "== 看内存/swap"
free -h; sudo swapon --show || true

echo "== 装依赖"
sudo apt-get update -qq
# 22.04 上没有 libncurses5/lib32ncurses5-dev，用 lib32ncurses-dev 代替
sudo apt-get install -y -qq git-core gnupg flex bison build-essential zip curl \
  zlib1g-dev libc6-dev-i386 lib32ncurses-dev libx11-dev lib32z1-dev \
  libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig python3

echo "== 同步 TWRP 源码 (twrp-12.1)"
mkdir -p "$HOME/bin" "$HOME/twrp"
curl -s https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/bin/repo"
chmod a+x "$HOME/bin/repo"
export PATH="$HOME/bin:$PATH"
git config --global user.name  "ci-bot"
git config --global user.email "ci-bot@users.noreply.github.com"
cd "$HOME/twrp"
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync -c -j"$(nproc --all)" --force-sync --no-clone-bundle --no-tags
rm -rf .repo
df -h /

echo "== 组装 device tree"
D="$HOME/twrp/device/vivo/PD2430"
mkdir -p "$D/prebuilt" "$D/recovery/root/system/etc" "$D/recovery/root/system/bin" "$D/recovery/root/first_stage_ramdisk"
cp "$GITHUB_WORKSPACE/BoardConfig.mk" "$GITHUB_WORKSPACE/device.mk" \
   "$GITHUB_WORKSPACE/AndroidProducts.mk" "$GITHUB_WORKSPACE/twrp_PD2430.mk" \
   "$GITHUB_WORKSPACE/system.prop" "$D/"
gunzip -c "$GITHUB_WORKSPACE/Image.gz" > "$D/prebuilt/Image"
ls -l "$D/prebuilt/Image"
cp "$GITHUB_WORKSPACE/dtb.img" "$D/prebuilt/dtb.img"
cp "$GITHUB_WORKSPACE/recovery.fstab" "$D/recovery/root/system/etc/recovery.fstab"
cp "$GITHUB_WORKSPACE/fstab.mt6989" "$D/recovery/root/first_stage_ramdisk/fstab.mt6989"
# stock vendor_boot 里的内核模块 + init.recovery.*.rc（显示/触摸/UFS 全靠它们）
tar xzf "$GITHUB_WORKSPACE/vendor-rec.tar.gz" -C "$D/recovery/root"
cp "$GITHUB_WORKSPACE/loadmods.sh" "$D/recovery/root/system/bin/loadmods.sh"
chmod 0755 "$D/recovery/root/system/bin/loadmods.sh"
cp "$GITHUB_WORKSPACE/init.recovery.mt6989.rc" "$D/recovery/root/"
cp "$GITHUB_WORKSPACE/init.recovery.usb.rc" "$D/recovery/root/"
ls "$D/recovery/root/lib/modules" | wc -l

echo "== 编译"
cd "$HOME/twrp"
set +u
export ALLOW_MISSING_DEPENDENCIES=true
export LC_ALL=C
source build/envsetup.sh
lunch twrp_PD2430-eng || { echo "--- 可用 lunch 组合 ---"; lunch 2>&1 | tail -40; exit 1; }
# remb(K60E) 同款：直接 vendorbootimage。recovery/root 会被构建系统自动合并进
# vendor_boot（build/core/Makefile 的 recovery_root_private 机制）。
make vendorbootimage -j2

echo "== 检查产物"
ls -l out/target/product/PD2430/vendor_boot.img
sha256sum out/target/product/PD2430/vendor_boot.img
du -sh out/target/product/PD2430/recovery/root out/target/product/PD2430/root out/target/product/PD2430/vendor_ramdisk 2>/dev/null || true
echo "--- recovery/root/system/bin 前 20 个文件 ---"
ls out/target/product/PD2430/recovery/root/system/bin/ 2>/dev/null | head -20 || true
echo "--- recovery/root 顶层 ---"
ls out/target/product/PD2430/recovery/root/ 2>/dev/null || true

echo "== 回传产物到仓库"
IMG=out/target/product/PD2430/vendor_boot.img
mkdir -p "$GITHUB_WORKSPACE/out"
gzip -9 -c "$IMG" > "$GITHUB_WORKSPACE/out/vendor_boot.img.gz"
cd "$GITHUB_WORKSPACE"
git add out/
git commit -m "build: $(date -u +%Y%m%d-%H%M) vendor_boot.img" || true
# 构建期间仓库可能被推过新提交，先变基再推，避免非快进被拒
git pull --rebase origin main || true
git push || echo "push 失败，产物仍在 Actions Artifacts 里"
