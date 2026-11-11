# shellcheck shell=bash
# Hibernation: a btrfs swap file as large as your memory, in its own subvolume (so snapshots never include
# it), plus the kernel "resume" arguments. Changes /etc/fstab and the boot entries.
[[ $(findmnt -no FSTYPE /) == btrfs ]] || {
    warn "The root filesystem isn't btrfs; this step only knows btrfs. Skipped."
    exit 0
}
uuid=$(findmnt -no UUID /)
size=$(awk '/MemTotal/ { printf "%dg", $2 / 1048576 + 2 }' /proc/meminfo) # memory + 2 GB, so an image always fits

if ! grep -q 'subvol=/@swap' /etc/fstab; then
    mnt=$(mktemp -d)
    run sudo mount -o subvolid=5 "/dev/disk/by-uuid/$uuid" "$mnt"
    [[ -d $mnt/@swap ]] || run sudo btrfs subvolume create "$mnt/@swap"
    run sudo umount "$mnt"
    rmdir "$mnt"
fi
run sudo mkdir -p /swap
fstab=$(cat /etc/fstab)
grep -q 'subvol=/@swap' <<<"$fstab" || fstab+=$'\n'"UUID=$uuid /swap btrfs subvol=/@swap,noatime 0 0"
grep -q '^/swap/swapfile' <<<"$fstab" || fstab+=$'\n'"/swap/swapfile none swap defaults,pri=0 0 0" # pri=0: zram is still used first
sys_write /etc/fstab "$fstab"
run sudo systemctl daemon-reload
mountpoint -q /swap || run sudo mount /swap
[[ -f /swap/swapfile ]] || run sudo btrfs filesystem mkswapfile --size "$size" /swap/swapfile
swapon --show=NAME --noheadings | grep -q '^/swap/swapfile$' || run sudo swapon -p 0 /swap/swapfile
sys_note "the swap file /swap/swapfile and the @swap subvolume (sudo swapoff /swap/swapfile; sudo rm /swap/swapfile)"

if $DRY; then offset="<offset>"; else offset=$(sudo btrfs inspect-internal map-swapfile -r /swap/swapfile); fi
distro_kernel_args hibernate "resume=UUID=$uuid resume_offset=$offset"
sys_write /etc/systemd/sleep.conf.d/50-hyprism-hibernate.conf "[Sleep]
HibernateDelaySec=60min"
say "Reboot once. After that, ./install.sh --only modules refreshes the lid rule so sleep turns into hibernate after an hour."
