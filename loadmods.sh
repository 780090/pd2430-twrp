#!/system/bin/sh
# 加载 stock vendor_boot 里的 recovery 内核模块。
# 优先 insmod -f（内核可能带强制加载），失败再普通 insmod，最后试 modprobe。
LOG=/tmp/loadmods.log
[ -f /lib/modules/modules.load.recovery ] || exit 0
: > $LOG
ok=0; fail=0
while read -r m; do
  [ -z "$m" ] && continue
  case "$m" in \#*) continue ;; esac
  if insmod -f "/lib/modules/$m" >>"$LOG" 2>&1; then ok=$((ok+1))
  elif insmod "/lib/modules/$m" >>"$LOG" 2>&1; then ok=$((ok+1))
  elif modprobe -f "$m" >>"$LOG" 2>&1; then ok=$((ok+1))
  else fail=$((fail+1)); echo "FAIL $m" >>"$LOG"; fi
done < /lib/modules/modules.load.recovery
echo "loaded=$ok failed=$fail" >>"$LOG"
