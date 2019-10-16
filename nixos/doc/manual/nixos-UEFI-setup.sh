#! @shell@

# Make sure you uncomment disk you want to set NixOS on sdX(HDD) or nvme0n1(SSD) for example
# if confused read more on
# http://tldp.org/HOWTO/html_single/Partition/
# To check list of avaliable disks run command:
# lsblk


# UNCOMMENT
#DISK_SSD="/dev/nvme0n1"
# OR
#DISK_HDD="/dev/sda"
NAME_DIVIDER=""

echo $DISK_SSD
if [[ -n $DISK_SSD ]]; then
    echo "Formating SSD disk to create partitions."
    DISK=$DISK_SSD
    NAME_DIVIDER="p"

elif [[ -n $DISK_HDD ]]; then
    echo "Formating HDD disk to create partitions."
    DISK=$DISK_HDD

else
    echo "Uncomment your disk according to your disk name"
    lsblk
    exit 1
fi



echo ""
echo "Partitioning "
echo "Note: You can safely ignore parted's informational message about needing to update /etc/fstab."
sleep 0.5s

# Create a GPT partition table. 
parted "$DISK" -- mklabel gpt
# Add the root partition. This will fill the disk except for the end part, where the swap will live, and the space left in front (512MiB) which will be used by the boot partition. 
parted "$DISK" -- mkpart primary 512MiB -8GiB
# Next, add a swap partition. The size required will vary according to needs, here a 8GiB one is created. 
parted "$DISK" -- mkpart primary linux-swap -8GiB 100%
# Finally, the boot partition. NixOS by default uses the ESP (EFI system partition) as its /boot partition. It uses the initially reserved 512MiB at the start of the disk. 
parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
parted "$DISK" -- set 3 boot on

echo ""
echo "Formatting "
sleep 0.5s

# For initialising Ext4 partitions: mkfs.ext4. It is recommended that you assign a unique symbolic label to the file system using the option -L label, since this makes the file system configuration independent from device changes. For example: 
mkfs.ext4 -L nixos "${DISK}${NAME_DIVIDER}1"
# For creating swap partitions: mkswap. Again it’s recommended to assign a label to the swap partition: -L label. For example: 
mkswap -L swap "${DISK}${NAME_DIVIDER}2"
# For creating boot partitions: mkfs.fat. Again it’s recommended to assign a label to the boot partition: -n label. For example: 
mkfs.fat -F 32 -n boot "${DISK}${NAME_DIVIDER}3"


echo ""
echo "Installing "
sleep 0.5s
# Mount the target file system on which NixOS should be installed on /mnt, e.g. 
mount /dev/disk/by-label/nixos /mnt
# Mount the boot file system on /mnt/boot, e.g. 
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
# If your machine has a limited amount of memory, you may want to activate swap devices now (swapon device). The installer (or rather, the build actions that it may spawn) may need quite a bit of RAM, depending on your configuration. 
swapon "${DISK}${NAME_DIVIDER}2"

# The command nixos-generate-config can generate an initial configuration file for you: 
nixos-generate-config --root /mnt

echo "More info on https://nixos.org/nixos/manual/index.html#sec-installation-installing "
echo ""
echo "You should edit /mnt/etc/nixos/configuration.nix to suit your needs: "
echo "$ nano /mnt/etc/nixos/configuration.nix "
echo "or "
echo "$ vim /mnt/etc/nixos/configuration.nix "





