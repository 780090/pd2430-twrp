#!/usr/bin/env bash
# PD2430 TWRP 14.0 构建脚本（X100 同款配方：nebrassy twrp-14 + ap2a lunch）
set -eo pipefail

echo "== 腾磁盘"
sudo rm -rf /usr/share/dotnet /opt/ghc /usr/local/lib/android /usr/local/share/boost "${AGENT_TOOLSDIRECTORY:-/opt/hostedtoolcache}" || true
df -h /

echo "== 看内存/swap"
free -h; sudo swapon --show || true

echo "== 装依赖"
sudo apt-get update -qq
sudo apt-get install -y -qq git-core gnupg flex bison build-essential zip curl \
  zlib1g-dev libc6-dev-i386 lib32ncurses-dev libx11-dev lib32z1-dev \
  libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig python3

echo "== 同步 TWRP 源码 (nebrassy twrp-14)"
mkdir -p "$HOME/bin" "$HOME/twrp"
curl -s https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/bin/repo"
chmod a+x "$HOME/bin/repo"
export PATH="$HOME/bin:$PATH"
git config --global user.name  "ci-bot"
git config --global user.email "ci-bot@users.noreply.github.com"
cd "$HOME/twrp"
repo init --depth=1 -u https://github.com/nebrassy/platform_manifest_twrp_aosp.git -b twrp-14
repo sync -c -j"$(nproc --all)" --force-sync --no-clone-bundle --no-tags
rm -rf .repo
# manifest 里有 prebuilts/misc 但缺 guava 模块：从 AOSP 补 guava 子树
ls -ld prebuilts/misc prebuilts/misc/.git 2>&1 | head -3
if [ -d prebuilts/misc/.git ]; then
  git -C prebuilts/misc fetch --depth=1 -q https://android.googlesource.com/platform/prebuilts/misc \
    refs/tags/android-14.0.0_r1 2>&1 | tail -1 || true
  git -C prebuilts/misc checkout -q FETCH_HEAD -- common/guava 2>&1 | tail -1 || true
else
  rm -rf prebuilts/misc
  git clone --depth=1 -q https://android.googlesource.com/platform/prebuilts/misc prebuilts/misc \
    -b android-14.0.0_r1 2>&1 | tail -1 || true
fi
ls prebuilts/misc/common/guava/ 2>/dev/null && echo "guava OK" || echo "guava 仍缺"
df -h /

echo "== 加 12G swap（kati 解析 14.0 全量配置内存会爆，VM 被收割）"
sudo fallocate -l 12G /home/runner/.swapfile && sudo chmod 600 /home/runner/.swapfile \
  && sudo mkswap /home/runner/.swapfile && sudo swapon /home/runner/.swapfile
free -h; sudo swapon --show

echo "== 组装 device tree"
D="$HOME/twrp/device/vivo/PD2430"
mkdir -p "$D/prebuilt" \
         "$D/recovery/root/system/etc" "$D/recovery/root/system/etc/vintf" \
         "$D/recovery/root/system/bin" "$D/recovery/root/first_stage_ramdisk"
cp "$GITHUB_WORKSPACE/BoardConfig.mk" "$GITHUB_WORKSPACE/device.mk" \
   "$GITHUB_WORKSPACE/AndroidProducts.mk" "$GITHUB_WORKSPACE/twrp_PD2430.mk" \
   "$GITHUB_WORKSPACE/system.prop" "$GITHUB_WORKSPACE/Android.mk" \
   "$GITHUB_WORKSPACE/Android.bp" "$D/"
gunzip -c "$GITHUB_WORKSPACE/Image.gz" > "$D/prebuilt/Image"
ls -l "$D/prebuilt/Image"
cp "$GITHUB_WORKSPACE/dtb.img" "$D/prebuilt/dtb.img"
cp "$GITHUB_WORKSPACE/recovery.fstab" "$D/recovery/root/system/etc/recovery.fstab"
cp "$GITHUB_WORKSPACE/twrp.flags" "$D/recovery/root/system/etc/twrp.flags"
cp "$GITHUB_WORKSPACE/manifest.xml" "$D/recovery/root/system/etc/vintf/manifest.xml"
cp "$GITHUB_WORKSPACE/fstab.mt6989" "$D/recovery/root/first_stage_ramdisk/fstab.mt6989"
# stock vendor_boot 里的内核模块 + init.recovery.{platform,svc,touch,wifi}.rc
tar xzf "$GITHUB_WORKSPACE/vendor-rec.tar.gz" -C "$D/recovery/root"
# 从本机 /vendor 提取的 trustonic 解密栈（兜底副本；主路径走真实 /vendor）
tar xzf "$GITHUB_WORKSPACE/vendor-trustonic.tar.gz" -C "$D/recovery/root"
cp "$GITHUB_WORKSPACE/init.recovery.mt6989.rc" "$D/recovery/root/"
cp "$GITHUB_WORKSPACE/init.recovery.usb.rc" "$D/recovery/root/"
cp "$GITHUB_WORKSPACE/init.recovery.trustonic.rc" "$D/recovery/root/"
cp "$GITHUB_WORKSPACE/prepdecrypt.sh" "$D/recovery/root/system/bin/prepdecrypt.sh"
chmod 0755 "$D/recovery/root/system/bin/prepdecrypt.sh"
ls "$D/recovery/root/lib/modules" | wc -l
find "$D" -type f | wc -l

echo "== 编译"
cd "$HOME/twrp"
set +u
export ALLOW_MISSING_DEPENDENCIES=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true
export LC_ALL=C
source build/envsetup.sh
lunch twrp_PD2430-ap2a-eng || { echo "--- 可用 lunch 组合 ---"; lunch 2>&1 | tail -40; exit 1; }
make vendorbootimage -j2

echo "== 检查产物"
ls -l out/target/product/PD2430/vendor_boot.img
sha256sum out/target/product/PD2430/vendor_boot.img
du -sh out/target/product/PD2430/recovery/root out/target/product/PD2430/root out/target/product/PD2430/vendor_ramdisk 2>/dev/null || true
echo "--- recovery/root/system/bin 前 20 个 ---"
ls out/target/product/PD2430/recovery/root/system/bin/ 2>/dev/null | head -20 || true

echo "== 回传产物到仓库"
IMG=out/target/product/PD2430/vendor_boot.img
mkdir -p "$GITHUB_WORKSPACE/out"
gzip -9 -c "$IMG" > "$GITHUB_WORKSPACE/out/vendor_boot.img.gz"
cd "$GITHUB_WORKSPACE"
git add out/
git commit -m "build14: $(date -u +%Y%m%d-%H%M) vendor_boot.img" || true
git pull --rebase origin main || true
git push || echo "push 失败，产物仍在 Actions Artifacts 里"
