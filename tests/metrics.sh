#!/usr/bin/env bash
# The metrics reader against made-up computers: a small fake /proc and /sys in a throwaway folder, so the
# numbers are known. Checks that every reading comes out right, that a computer without a sensor just leaves
# it out, and that a sleeping second graphics card is never asked for numbers.
#   tests/metrics.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
export HYPRISM_LIB=$PWD/config/scripts/.local/lib/hyprism
m=$PWD/config/scripts/.local/bin/metrics
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
fail=0
put() {
    mkdir -p "$1$(dirname "$2")"
    printf '%s\n' "$3" >"$1$2"
}
# expect NAME JQ-FILTER WANTED: one value out of the JSON
expect() {
    local got
    got=$(jq -r "$2" <<<"$json" 2>/dev/null)
    if [[ $got == "$3" ]]; then echo "ok: $1"; else
        echo "xx $1: expected '$3', got '$got'"
        fail=1
    fi
}

# --- a laptop with everything: AMD CPU, built-in AMD card, a sleeping NVIDIA card, battery, two fans
r=$t/laptop
put "$r" /proc/stat "cpu  100 0 100 700 100 0 0 0
cpu0 50 0 50 350 50 0 0 0
cpu1 50 0 50 350 50 0 0 0
intr 1"
put "$r" /proc/meminfo "MemTotal:       16000000 kB
MemAvailable:   12000000 kB
SwapTotal:       8000000 kB
SwapFree:        6000000 kB"
put "$r" /proc/uptime "3600.55 1000.00"
put "$r" /proc/loadavg "0.50 0.40 0.30 1/500 1234"
put "$r" /proc/net/dev "Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo: 999 1 0 0 0 0 0 0 999 1 0 0 0 0 0 0
 wlan0: 5000 10 0 0 0 0 0 0 2000 10 0 0 0 0 0 0
docker0: 777 1 0 0 0 0 0 0 777 1 0 0 0 0 0 0"
put "$r" /proc/net/route "Iface	Destination	Gateway
wlan0	00000000	0101A8C0"
put "$r" /proc/diskstats "   259       0 nvme0n1 100 0 2000 0 50 0 1000 0 0 0 0
   259       1 nvme0n1p1 100 0 9999 0 50 0 9999 0 0 0 0"
put "$r" /sys/class/hwmon/hwmon0/name k10temp
put "$r" /sys/class/hwmon/hwmon0/temp1_input 61500
put "$r" /sys/class/hwmon/hwmon1/name somefans
put "$r" /sys/class/hwmon/hwmon1/fan1_input 3600
put "$r" /sys/class/hwmon/hwmon1/fan2_input 4000
put "$r" /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2000000
put "$r" /sys/devices/system/cpu/cpu1/cpufreq/scaling_cur_freq 3000000
put "$r" /sys/bus/pci/devices/0000:08:00.0/gpu_busy_percent 12
put "$r" /sys/bus/pci/devices/0000:08:00.0/mem_info_vram_used 536870912
put "$r" /sys/bus/pci/devices/0000:08:00.0/mem_info_vram_total 1073741824
put "$r" /sys/bus/pci/devices/0000:08:00.0/hwmon/hwmon5/temp1_input 48000
put "$r" /sys/bus/pci/devices/0000:08:00.0/hwmon/hwmon5/power1_average 9500000
put "$r" /sys/bus/pci/devices/0000:01:00.0/power/runtime_status suspended
put "$r" /sys/bus/pci/devices/0000:01:00.0/gpu_busy_percent 99 # a trap: must not be read while it sleeps
put "$r" /sys/class/power_supply/BAT1/capacity 59
put "$r" /sys/class/power_supply/BAT1/status Discharging
put "$r" /sys/class/power_supply/BAT1/power_now 12000000
put "$r" /sys/class/power_supply/BAT1/energy_now 36000000
put "$r" /sys/class/power_supply/BAT1/energy_full 60000000
put "$r" /sys/firmware/acpi/platform_profile balanced
cat >"$t/laptop.toml" <<'EOF'
[gpu]
primary_pci = "0000:08:00.0"
discrete = "nvidia"
discrete_pci = "0000:01:00.0"
[power]
battery = "BAT1"
EOF

json=$(HYPRISM_ROOT=$r HYPRISM_HARDWARE=$t/laptop.toml bash "$m" once)
expect "the output is one JSON object" 'type' object
expect "cpu load is 0 when nothing changed between samples" '.cpu.pct' 0
expect "one entry per core" '.cpu.cores | length' 2
expect "cpu temperature from the sensor found by name" '.cpu_temp' 61.5
expect "cpu frequency is the average of the cores, in MHz" '.cpu_freq' 2500
expect "built-in card load" '.gpu.pct' 12
expect "built-in card memory in MB" '.gpu.vram_used' 512
expect "built-in card temperature" '.gpu.temp == 48' true
expect "built-in card power in watts" '.gpu.watts' 9.5
expect "a sleeping second card reports its state" '.dgpu.state' suspended
expect "and nothing else (it is never asked while asleep)" '.dgpu | keys | join(",")' state
expect "memory used in MB" '.ram.used' 3906
expect "memory percent" '.ram.pct' 25
expect "swap percent" '.swap.pct' 25
expect "network: the interface of the default route" '.net.iface' wlan0
expect "network rate is 0 with unchanged counters" '.net.down' 0
expect "disk i/o counts whole disks only" '.diskio.read' 0
expect "battery percent" '.battery.pct' 59
expect "battery state" '.battery.state' discharging
expect "battery power in watts" '.battery.watts == 12' true
expect "battery minutes left" '.battery.minutes' 180
expect "every fan" '.fans | join(",")' 3600,4000
expect "power profile" '.profile' balanced
expect "uptime in seconds" '.uptime' 3600
expect "load average" '.load[0]' 0.50
expect "no disk list from a made-up root" '.disk' null

# rates: change the counters between two ticks of one run
json=$(
    (
        sleep 1.4
        put "$r" /proc/net/dev "h1
h2
 wlan0: 105000 10 0 0 0 0 0 0 52000 10 0 0 0 0 0 0"
        put "$r" /proc/stat "cpu  300 0 100 700 100 0 0 0
cpu0 150 0 50 350 50 0 0 0
cpu1 150 0 50 350 50 0 0 0"
    ) &
    HYPRISM_ROOT=$r HYPRISM_HARDWARE=$t/laptop.toml timeout 2.6 bash "$m" watch cpu,net 1 | tail -1
)
down=$(jq -r '.net.down' <<<"$json")
if [[ $down =~ ^[0-9]+$ ]] && ((down > 50000 && down < 200000)); then echo "ok: network rate follows the counters ($down B/s)"; else
    echo "xx network rate: expected about 100000 B/s, got '$down'"
    fail=1
fi
expect "cpu load follows the counters" '.cpu.pct' 100

# --- a bare desktop: Intel CPU, no battery, no fans, one card with no readings
r=$t/desktop
put "$r" /proc/stat "cpu  1 0 1 8 0 0 0 0"
put "$r" /proc/meminfo "MemTotal:       8000000 kB
MemAvailable:   4000000 kB
SwapTotal:             0 kB
SwapFree:              0 kB"
put "$r" /proc/uptime "10.0 5.0"
put "$r" /proc/loadavg "1.00 1.00 1.00 1/1 1"
put "$r" /sys/class/hwmon/hwmon0/name coretemp
put "$r" /sys/class/hwmon/hwmon0/temp1_input 40000
: >"$t/desktop.toml"
json=$(HYPRISM_ROOT=$r HYPRISM_HARDWARE=$t/desktop.toml bash "$m" once)
expect "desktop: still one JSON object" 'type' object
expect "desktop: Intel CPU temperature" '.cpu_temp == 40' true
expect "desktop: what it lacks is left out" '[.battery, .fans, .dgpu, .gpu, .swap, .profile] | map(select(. != null)) | length' 0
expect "desktop: memory" '.ram.pct' 50

# --- the command line
out=$(HYPRISM_ROOT=$r HYPRISM_HARDWARE=$t/desktop.toml bash "$m" once nosuch 2>&1) && {
    echo "xx an unknown metric name must fail"
    fail=1
}
[[ $out == *"no such metric"* ]] && echo "ok: an unknown metric is refused by name"
if [[ $(bash "$m" list | wc -l) == 15 ]]; then echo "ok: metrics list names all 15"; else
    echo "xx metrics list"
    fail=1
fi

exit "$fail"
