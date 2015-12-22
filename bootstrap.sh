sudo -s
cd /home/vagrant

apt-get update
apt-get install -y git binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools

dd if=/dev/zero of=rpi.img bs=1M count=768
LOOP_DEVICE=`losetup -f --show rpi.img`
cat /vagrant/templates/fdisk | fdisk $LOOP_DEVICE

losetup -d /dev/loop0
kpartx -va rpi.img
mkfs.fat /dev/mapper/loop0p1
mkfs.ext4 /dev/mapper/loop0p2
mkdir boot root
mount /dev/mapper/loop0p1 boot
mount /dev/mapper/loop0p2 root

debootstrap --arch armhf --foreign jessie root http://ftp.debian.org/debian/
cp /usr/bin/qemu-arm-static root/usr/bin/
LANG=C chroot root /debootstrap/debootstrap --second-stage
chroot root /bin/bash -c "echo \"root:raspberry\" | chpasswd"

cp /vagrant/templates/root/etc/fstab root/etc/fstab
cp /vagrant/templates/root/etc/hostname root/etc/hostname
cp /vagrant/templates/root/etc/apt/sources.list root/etc/apt/sources.list

mkdir -p root/lib/modules
curl -L --output /usr/bin/rpi-update https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update
chmod +x /usr/bin/rpi-update
SKIP_BACKUP=1 UPDATE_SELF=0 BOOT_PATH=boot ROOT_PATH=root rpi-update
echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rw rootwait" > boot/cmdline.txt

cp /vagrant/templates/boot/config.txt boot/
cp /vagrant/templates/root/etc/network/interfaces/lo root/etc/network/interfaces

mount -t proc proc root/proc
mount --rbind /dev root/dev

cp /vagrant/templates/root/etc/apt/apt.conf.d/00norecommends root/etc/apt/apt.conf.d

chroot root /bin/bash -c "apt-get update"
chroot root /bin/bash -c "LANG=C apt-get install locale"

cp /vagrant/templates/root/etc/locale.gen root/etc/

chroot root /bin/bash -c "locale-gen"

chroot root /bin/bash -c "apt-get -y install openssh-server openssh-blacklist openssh-blacklist-extra sudo python aptitude resolvconf"

chroot root /bin/bash -c "apt-get autoremove --purge"
chroot root /bin/bash -c "apt-get clean"

cp /home/vagrant/rpi.img /vagrant/

echo 'Done. Your image has been saved to rpi.img file. You can now use vagrant destroy command.'
