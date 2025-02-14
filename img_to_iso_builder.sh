#!/bin/bash

# Set the disk image filename and disk ID
disk_image="tails-amd64-6.12.img"
disk_id="tails"

# Check if the disk image has a partition table
echo "Checking the disk image: $disk_image"

# Check if GPT partitioning is present
if fdisk -l "$disk_image" | grep -q "Disklabel type: gpt"; then
    echo "GPT partitioning detected."
elif fdisk -l "$disk_image" | grep -q "DOS/MBR"; then
    echo "MBR boot sector detected."
else
    echo "No partition table detected."
fi

# Check if partitions exist
if fdisk -l "$disk_image" | grep -q "Device"; then
    echo "Partitions exist."
else
    echo "No partitions detected. Exiting..."
    exit 1
fi

# Check if /dev/mapper exists
if ls /dev/mapper/ &>/dev/null; then
    echo "/dev/mapper exists."
else
    echo "/dev/mapper does not exist. Exiting..."
    exit 1
fi

# Check if the loop device loop0p1 already exists
if [ -e /dev/mapper/loop0p1 ]; then
    echo "/dev/mapper/loop0p1 already exists. Skipping loop device creation."
    sudo umount /mnt/${disk_id}_img
    sudo dmsetup remove /dev/loop0
    sudo dmsetup remove /dev/mapper/loop0p1
else
    # Create the loop device using kpartx (this will create devices like /dev/mapper/loop0p1, /dev/mapper/loop0p2, etc.)
    echo "Creating loop device with kpartx..."
    sudo kpartx -av "$disk_image"
fi

# Ensure loop device names are consistent and that we don't accidentally pick any other loop device
loop_device=$(ls /dev/mapper/ | grep -E "^loop0p1$" | head -n 1)

if [ -z "$loop_device" ]; then
    echo "Loop device (loop0p1) creation failed. Exiting..."
    exit 1
else
    echo "Loop device $loop_device created successfully."
fi

# Ensure the mount point exists
mkdir -p /mnt/${disk_id}_img

# Mount the partition (loop device should be loop0p1 if the image has a single partition)
echo "Mounting the loop device..."
sudo mount /dev/mapper/$loop_device /mnt/${disk_id}_img/

# Confirm the mount
if mount | grep -q "/mnt/${disk_id}_img"; then
    echo "Device mounted successfully at /mnt/${disk_id}_img"
else
    echo "Mounting failed. Exiting..."
    exit 1
fi

# Prompt user for input
read -p "Do you want to skip unsquash and squash section? (yes/no): " answer

# Convert answer to lowercase to handle case-insensitivity
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

# Validate user input and decide whether to skip
if [[ "$answer" == "yes" ]]; then
    echo "Skipping section..."
else
	# Step 1: Extract the SquashFS from the Tails image
	echo "Extracting SquashFS from the Tails image..."
	sudo rm -rf /mnt/squashfs && sudo mkdir -p /mnt/squashfs

	sudo unsquashfs -d /mnt/squashfs /mnt/${disk_id}_img/live/filesystem.squashfs

	# Step 2: Copy your binaries (cryptsetup and related files) into the extracted SquashFS
	echo "Copying binaries into the SquashFS filesystem..."
	sudo cp ./binaries/cryptsetup/cryptsetup /mnt/squashfs/bin
	sudo cp ./binaries/cryptsetup/cryptdisks_start /mnt/squashfs/bin
	sudo cp ./binaries/cryptsetup/cryptdisks_stop /mnt/squashfs/bin
	sudo cp ./binaries/cryptsetup/*.so* /mnt/squashfs/lib64

	# Define less critical directories
	dirs_to_remove=(
	    "usr/share/akonadi"
	    "usr/share/alsa"
	    "usr/share/application-registry"
	    "usr/share/brasero"
	    "usr/share/cmake"
	    "usr/share/colord"
	    "usr/share/djvu"
	    "usr/share/doc"
	    "usr/share/emacs"
	    "usr/share/evolution-data-server"
	    "usr/share/ffmpeg"
	    "usr/share/file-roller"
	    "usr/share/gimp"
	    "usr/share/git-core"
	    "usr/share/inkscape"
	    "usr/share/kleopatra"
	    "usr/share/keepassxc"
	    "usr/share/libchewing"
	    "usr/share/libgnomekbd"
	    "usr/share/maven-repo"
	    "usr/share/hunspell"
	    "usr/share/help"
	    "usr/share/nodejs"
	    "usr/share/nautilus"
	    "usr/share/man"
	    "usr/share/onionshare"
	    "usr/share/openal"
	    "usr/share/opencc"
	    "usr/share/orca"
	    "usr/share/perl"
	    "usr/share/python-apt"
	    "usr/share/python3"
	    "usr/share/qt5"
	    "usr/share/system-config-printer"
	    "usr/share/thunderbird"
	    "usr/share/tor"
	    "usr/share/tracker3"
	    "usr/share/usb_modeswitch"
	    "usr/share/wallpapers"
	    "usr/share/zenity"
	    "usr/share/fonts/opentype"
	    "usr/share/common-licenses"
	    "usr/share/dictionaries-common"
	    "usr/include/aircrack-ng"
	    "usr/include/gcalc-2"
	    "usr/include/gci-2"
	    "etc/tor-browser"
	    "etc/tor"
	    "etc/vulkan"
	    "etc/whisperback"
	    "etc/cron.d"
	    "etc/cron.daily"
	    "etc/cron.monthly"
	    "etc/cron.hourly"
	    "etc/cron.yearly"
	    "etc/gimp"
	)

	# Loop through and remove directories if they exist
	for dir in "${dirs_to_remove[@]}"; do
	    target_dir="/mnt/squashfs/$dir"
	    
	    if [ -d "$target_dir" ]; then
		sudo rm -rf "$target_dir"
		echo "Removed $target_dir"
	    else
		echo "$target_dir does not exist, skipping."
	    fi
	done
	
	# Step 3: Rebuild the SquashFS with the new files
	# Rebuild the SquashFS with the new binaries
	echo "Rebuilding the SquashFS with the new binaries..."
	sudo mksquashfs /mnt/squashfs ./filesystem.squashfs -comp xz

	# Confirm the SquashFS was rebuilt successfully
	if [ $? -eq 0 ]; then
	    echo "SquashFS rebuilt successfully with the new binaries."
	else
	    echo "Error rebuilding SquashFS. Exiting..."
	    exit 1
	fi
fi


# Ask the user for the USB device to format
echo "Please enter the USB device (e.g., /dev/sda1 or /dev/sda2):"
read -r usb_device

# Ensure the USB device exists
if [ ! -e "$usb_device" ]; then
    echo "The USB device $usb_device does not exist. Exiting..."
    exit 1
fi

# Check if the mount point already exists
mount_point="/mnt/usb"
if [ -d "$mount_point" ]; then
    echo "The mount point $mount_point already exists"
else
    # Create the mount point
    echo "Creating mount point $mount_point..."
    mkdir -p "$mount_point"
fi

# Format the USB device as an EFI system partition
echo "Formatting $usb_device as an EFI system partition..."
sudo mkfs.vfat -F32 -n "EFI" "$usb_device"

# Mount the USB device
echo "Mounting the USB device $usb_device at $mount_point..."
sudo mount "$usb_device" "$mount_point"

# Confirm the mount
if mount | grep -q "$mount_point"; then
    echo "USB device mounted successfully at $mount_point"
else
    echo "Mounting USB device failed. Exiting..."
    exit 1
fi

# Print the directory tree of the Tails image mount point
echo "Directory structure of the Tails image mount point:"
tree -L 2 /mnt/${disk_id}_img

# Now we can proceed with copying the Tails image content to the USB mount point

echo "Copying Tails image files to the USB device..."

# Use rsync or cp to copy the files to the USB (we'll use rsync for efficiency)
sudo rsync -a --progress --exclude 'live/filesystem.squashfs' /mnt/${disk_id}_img/ /mnt/usb/
sudo rsync -a --progress ./filesystem.squashfs /mnt/usb/live/

# Confirm the copy was successful
if [ $? -eq 0 ]; then
    echo "Files successfully copied to the USB device."
else
    echo "There was an error while copying files to the USB device. Exiting..."
    exit 1
fi

# Remove the EFI, syslinux, and utils directories from the USB device
echo "Removing EFI, syslinux, and utils directories from the USB device..."

sudo rm -rf /mnt/usb/EFI
sudo rm -rf /mnt/usb/syslinux
sudo rm -rf /mnt/usb/utils

# Confirm that the directories were removed
if [ ! -e /mnt/usb/EFI ] && [ ! -e /mnt/usb/syslinux ] && [ ! -e /mnt/usb/utils ]; then
    echo "EFI, syslinux, and utils directories successfully removed."
else
    echo "There was an error removing the directories. Exiting..."
    exit 1
fi

#!/bin/bash

# Get the UUID of the USB partition
usb_uuid=$(lsblk -o NAME,MOUNTPOINT,UUID | grep "/mnt/usb" | awk '{print $3}')

# Ensure UUID was found
if [ -z "$usb_uuid" ]; then
    echo "UUID not found for the USB partition $usb_device. Exiting..."
    exit 1
fi

# Template for GRUB configuration
grub_cfg_template=$(cat <<EOF
menuentry 'Tails (on $usb_device)' {
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=root $usb_uuid
    linux /live/vmlinuz boot=live splash noautologin
    initrd /live/initrd.img
}
EOF
)

# Ensure the boot directory exists
sudo mkdir -p /mnt/usb/boot

# Install GRUB2 to the USB
echo "Installing GRUB2 to the USB device..."
sudo grub2-install --target=x86_64-efi --efi-directory=/mnt/usb --boot-directory=/mnt/usb/boot --removable --force

# Write the GRUB configuration to the USB
echo "Writing GRUB configuration to /mnt/usb/boot/grub2/grub.cfg..."
echo "$grub_cfg_template" | sudo tee /mnt/usb/boot/grub2/grub.cfg

# Confirm the changes
if [ -e /mnt/usb/boot/grub2/grub.cfg ]; then
    echo "GRUB configuration written successfully."
else
    echo "Failed to write the GRUB configuration. Exiting..."
    exit 1
fi

