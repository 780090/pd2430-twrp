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

echo "== 同步 TWRP 14.0 源码"
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
mkdir -p "$D/prebuilt" "$D/recovery/root/system/etc" "$D/recovery/root/first_stage_ramdisk"
cp "$GITHUB_WORKSPACE/BoardConfig.mk" "$GITHUB_WORKSPACE/device.mk" \
   "$GITHUB_WORKSPACE/AndroidProducts.mk" "$GITHUB_WORKSPACE/twrp_PD2430.mk" \
   "$GITHUB_WORKSPACE/system.prop" "$D/"
cp "$GITHUB_WORKSPACE/dtb.img" "$D/prebuilt/dtb.img"
cp "$GITHUB_WORKSPACE/recovery.fstab" "$D/recovery/root/system/etc/recovery.fstab"
cp "$GITHUB_WORKSPACE/fstab.mt6989" "$D/recovery/root/first_stage_ramdisk/fstab.mt6989"
# stock vendor_boot 里的内核模块 + init.recovery.mt6989.rc（显示/触摸/UFS 全靠它们）
tar xzf "$GITHUB_WORKSPACE/vendor-rec.tar.gz" -C "$D/recovery/root"
cp "$GITHUB_WORKSPACE/init.recovery.mt6989.rc" "$D/recovery/root/"
ls "$D/recovery/root/lib/modules" | wc -l
find "$D" -type f | sort

echo "== 编译"
cd "$HOME/twrp"
set +u
export ALLOW_MISSING_DEPENDENCIES=true
export LC_ALL=C
source build/envsetup.sh
lunch twrp_PD2430-eng || { echo "--- 可用 lunch 组合 ---"; lunch 2>&1 | tail -40; exit 1; }
make vendorbootimage -j2

echo "== 回传产物到仓库"
ls -l out/target/product/PD2430/ || true
IMG=$(ls out/target/product/PD2430/*.img 2>/dev/null | head -1)
if [ -n "$IMG" ]; then
  mkdir -p "$GITHUB_WORKSPACE/out"
  gzip -9 -c "$IMG" > "$GITHUB_WORKSPACE/out/$(basename "$IMG").gz"
  cd "$GITHUB_WORKSPACE"
  git config user.name  "ci-bot"
  git config user.email "ci-bot@users.noreply.github.com"
  git add out/
  git commit -m "build: $(date -u +%Y%m%d-%H%M) $(basename "$IMG")" || true
  git push
else
  echo "没有找到 .img 产物，看看上面的编译日志"; exit 1
fi
