#!/usr/bin/env bash
# system/nvme-disks-temperatures (root only: run as root of a user
# namespace on a copy whose /dev/nvmeN glob points to scratch): a disk whose
# smart log cannot be read makes the run fail.
. "$(dirname "$0")/lib.sh"
need_userns

dev="$WORK/dev"
mkdir -p "$dev"
# Character devices stand in for the NVMe controllers.
ln -s /dev/null "$dev/nvme0"
ln -s /dev/null "$dev/nvme1"
script="$(patched system/nvme-disks-temperatures "s|/dev/nvme|$dev/nvme|g")" || exit 1

stub nvme '[[ -n "$FAIL" && "$2" == *nvme1 ]] && { printf "smart log: permission denied\n" >&2; exit 1; }
printf "Smart Log for NVME device:%s namespace-id:ffffffff\n" "${2##*/}"
printf "critical_warning\t\t\t: 0\n"
printf "temperature\t\t\t\t: 35 C (308 K)\n"
printf "available_spare\t\t\t\t: 100%%\n"
printf "Temperature Sensor 1           : 45 C (318 K)\n"
printf "Temperature Sensor 2           : 33 C (306 K)\n"'

run_nvme() {
	FAIL="$1" "$UNSHARE_BIN" -r "$BASH_BIN" "$script" > "$WORK/out" 2>&1
}

run_nvme ''
rc=$?
check "two disks: exit 0 (got $rc)" test "$rc" -eq 0
check 'two disks: both listed' test "$(grep -c 'TEMPS' "$WORK/out")" -eq 2
check 'two disks: ASIC temperature shown' grep -q 'ASIC CHIP.*45 C' "$WORK/out"

run_nvme 1
rc=$?
check "smart log of one disk fails: exit 1 (got $rc)" test "$rc" -eq 1

done_testing
