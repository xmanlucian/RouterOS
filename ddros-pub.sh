#!/bin/bash

###install needed command
echo '---install curl wget gzip---'
if [ -f /etc/os-release ]; then
	distro=`awk -F '=|"' '/^NAME=/{print $3}' /etc/os-release`
	case $distro in
		'CentOS Linux' | 'Oracle Linux' | 'Amazon Linux' )
			echo 'yum -y -q install curl wget gzip rsync gdisk dosfstools'
			yum check-update
			yum -y -q install curl wget gzip rsync gdisk dosfstools
			;;
		'Ubuntu' | 'Debian GNU/Linux')
			echo 'apt-get -y -q install curl wget gzip rsync gdisk dosfstools'
			#apt-get --allow-releaseinfo-change update
			apt-get update
			apt-get -y -q install curl wget gzip rsync gdisk dosfstools
			;;
		'Fedora' | 'Rocky Linux')
			echo 'dnf -y -q install curl wget gzip rsync gdisk dosfstools'
			dnf check-update
			dnf -y -q install curl wget gzip rsync gdisk dosfstools
			;;
		*)
			echo 'Unsupported distribution!'
			exit 1
			;;
	esac
	[ $? -ne 0 ] && echo 'Tools installation failed!' && exit 1
else
	echo '/etc/os-release does not exist!'
	exit 1
fi

###check vps basic infomation
echo '---vps basic information---'
#ethernet interface
ETHERS=(`ls /sys/class/net/ | grep -v "\`ls /sys/devices/virtual/net/\`"`)
echo "ethernet interface : ${ETHERS[*]}"

#ip addresses
#caution: not support that one interface has more than one address
MAC=()
ADDR=()
ADDR6=()
for (( i=0; i<${#ETHERS[@]}; i++ ))
do 
	MAC[$i]=`ip link show ${ETHERS[$i]} | awk '/link\/ether/ {print toupper($2)}'`
	ADDR[$i]=`ip address show ${ETHERS[$i]} | awk '$0 ~ "inet .*global" {print$2}'`
	ADDR6[$i]=`ip address show ${ETHERS[$i]} | awk '$0 ~ "inet6 .*global" {print$2}'`
	echo "    ${ETHERS[$i]} : mac=${MAC[$i]}; ipv4=${ADDR[$i]}; ipv6=${ADDR6[$i]}"
done

#gateway
GATEWAY=`ip route list | grep "^default via" | grep -v "\`ls /sys/devices/virtual/net\`" | awk '{print $3}'`
echo "gateway : $GATEWAY"

#gateway ipv6
GATE6=()
GATE6DEV=()
ROUTE6=(`ip -6 route list | awk '/^default via/ {print $3","$5}'`)
for (( i=0; i<${#ROUTE6[@]}; i++ ))
do 
	GATE6[$i]=${ROUTE6[$i]%,*}
	TMPDEV=${ROUTE6[$i]#*,}
	for (( j=0; j<${#ETHERS[@]}; j++ ))
	do 
		if [ "$TMPDEV" = ${ETHERS[$j]} ]; then
			GATE6DEV[$i]=$j
			break
		fi
	done
	echo "gateway6 : ${GATE6[$i]} dev $TMPDEV interface index ${GATE6DEV[$i]}"
done

#disk
DSTDISK=`lsblk -o PKNAME,MOUNTPOINT | awk '$2 == "/" {print $1}'`
echo "disk : $DSTDISK"
echo '---'

read -r -p "VPS basic information above is correct? [Y/n]:" input
case $input in
  [yY][eE][sS]|[yY])  
	;;
  *) 
	echo 'Exit for wrong vps information!'; 
	exit 1
	;;
esac

###check ros config data
echo '---ROS private config data---'

#ros license account
ROSACCOUNT=""
ROSPASSWD=""
[ -z "$ROSACCOUNT" ] && read -r -p "Input ROS license account:" ROSACCOUNT
[ -z "$ROSPASSWD" ] && read -r -p "Input ROS license password:" ROSPASSWD

#access config
PASSWORD=""
[ -z "$PASSWORD" ] && read -r -p "Input ROS admin password:" PASSWORD

SSHPORT=""
WINBOXPORT=""
[ -z "$SSHPORT" ] && read -r -p "Input ROS ssh port:" SSHPORT
[ -z "$WINBOXPORT" ] && read -r -p "Input ROS winbox port:" WINBOXPORT

DNSSVR="1.1.1.1,1.0.0.1"
[ -z "$DNSSVR" ] && read -r -p "Input ROS dns server:" DNSSVR

echo '---'
echo "ROS license user: $ROSACCOUNT ; pass: $ROSPASSWD"
echo "ROS admin password: $PASSWORD"
echo "ROS ssh port: $SSHPORT ; winbox port: $WINBOXPORT"
echo "ROS dns server: $DNSSVR"
echo '---End of ROS private config data---'
read -r -p "ROS config data above is correct? [Y/n]:" input
case $input in
  [yY][eE][sS]|[yY])  
	;;
  *) 
	echo 'Exit for wrong ROS config data!'; 
	exit 1
	;;
esac

#######download and extract ROS image zip file
#ros version
#ROS_VER="6.49.15"
ROS_VER=` curl -sL https://download.mikrotik.com/routeros/latest-stable-and-long-term.rss | awk '/\[stable\]/ {print $2}' `
echo "ROS image version : $ROS_VER"

#download image zip file
wget https://download.mikrotik.com/routeros/$ROS_VER/chr-$ROS_VER.img.zip -O chr.img.zip
[ $? -ne 0 ] && echo 'ROS image zip file download failed!' && exit 1

#extract image zip file to ramfs
mkdir -p /mnt/img
mount -t ramfs rampart /mnt/img
gunzip -c chr.img.zip > /mnt/img/chr.img
[ $? -ne 0 ] && echo 'Error on extract image file!' && exit 1

########modify image
###losetup loop device
LOOPDEV=`losetup --show -f -P /mnt/img/chr.img 2>/dev/null`
[ $? -ne 0 -o -z "$LOOPDEV" ] && echo 'losetup failed!' && exit 1
mkdir -p /mnt/ros

###uefi boot partition,convert to Hybrid MBR,format to FAT16 
if [ -d /sys/firmware/efi ]; then
	BOOTPART=`ls $LOOPDEV?* 2>/dev/null | awk 'NR == 1 {print $1}'`
	[ -z "$BOOTPART" ] && echo 'boot partition is null!' && exit 1
	
	mount $BOOTPART /mnt/ros
	[ $? -ne 0 ] && echo "Boot partition mount failed!" && exit 1

	[ -d ./efidata ] && rm -rf ./efidata/*
	mkdir -p ./efidata
	rsync -a /mnt/ros/ ./efidata/
	umount /mnt/ros
	
	#convert to uefi FAT16
	#from https://github.com/tikoci/fat-chr/blob/main/build.bash It works, but it is wired to change efi partition to linux file system
	#echo -e "2\nt\n1\n8300\nr\nh\n1 2\nn\n\ny\n\nn\nn\nw\ny\n" | gdisk $LOOPDEV
	#keep efi partition and make hybrid MBR in which the first partition is linux file system
	echo -e "2\nr\nh\n1 2\nn\n83\ny\n\nn\nn\nw\ny\n" | gdisk $LOOPDEV
	mkfs.fat -F 16 $BOOTPART
	
	mount $BOOTPART /mnt/ros
	rsync -a ./efidata/ /mnt/ros/ 
	umount /mnt/ros
fi

###write to config file
#mount img
LOOPPART=`ls $LOOPDEV?* 2>/dev/null | awk 'END {print $1}'`
[ -z "$LOOPPART" ] && echo 'Partition is null!' && exit 1
mount $LOOPPART /mnt/ros
[ $? -ne 0 ] && echo "Mount failed!" && exit 1

echo 'Writing to autorun.scr...'

VER_6=`echo $ROS_VER | grep "^6"`

#writing to auto config script
cat > /mnt/ros/rw/autorun.scr <<EOF
/ip service disable telnet,ftp,www,api,api-ssl
/tool mac-server set allowed-interface-list=none
/ip neighbor discovery-settings set discover-interface-list=none
/ip dhcp-client disable [find]
EOF

#password
[ -n "$PASSWORD" ] && echo "/user set 0 name=admin password=$PASSWORD" >> /mnt/ros/rw/autorun.scr

#access port
[ -n "$SSHPORT" ] && echo "/ip service set ssh port=$SSHPORT" >> /mnt/ros/rw/autorun.scr
[ -n "$WINBOXPORT" ] && echo "/ip service set winbox port=$WINBOXPORT" >> /mnt/ros/rw/autorun.scr

#config dns
[ -n "$DNSSVR" ] && echo "/ip dns set servers=$DNSSVR" >> /mnt/ros/rw/autorun.scr

#echo "/ip dns set servers=223.5.5.5,119.29.29.29" >> /mnt/ros/rw/autorun.scr
#echo "/ip dns static add cname=upgrade.mikrotik.app name=upgrade.mikrotik.com type=CNAME" >> /mnt/ros/rw/autorun.scr
#echo "/ip dns static add cname=licence.mikrotik.app name=licence.mikrotik.com type=CNAME" >> /mnt/ros/rw/autorun.scr

#ip address
echo ":local intfName" >> /mnt/ros/rw/autorun.scr
for (( i=0; i<${#ETHERS[@]}; i++ ))
do 
	echo ":set intfName [ /interface get value-name=name number=[ find where mac-address=${MAC[$i]} ] ] " >> /mnt/ros/rw/autorun.scr
	[ -n "${ADDR[$i]}" ] && echo "/ip address add address=${ADDR[$i]} interface=\$intfName" >> /mnt/ros/rw/autorun.scr
	[ -n "${ADDR6[$i]}" -a -z "$VER_6" ] && echo "/ipv6 address add address=${ADDR6[$i]} interface=\$intfName" >> /mnt/ros/rw/autorun.scr
done

#gateway
[ -n "$GATEWAY" ] && echo "/ip route add gateway=$GATEWAY" >> /mnt/ros/rw/autorun.scr

#gateway ipv6
if [ -z "$VER_6" ]; then
	for (( i=0; i<${#GATE6[@]}; i++ ))
	do 
		macaddr=${MAC[${GATE6DEV[$i]}]}
		echo ":set intfName [ /interface get value-name=name number=[ find where mac-address=$macaddr ] ] " >> /mnt/ros/rw/autorun.scr
		echo "/ipv6 route add gateway=\"${GATE6[$i]}%\$intfName\" " >> /mnt/ros/rw/autorun.scr
	done
fi

#license
if [ -n "$ROSACCOUNT" -a -n "$ROSPASSWD" ]; then
cat >> /mnt/ros/rw/autorun.scr <<EOF
#renew license
/delay 3s
/system license renew account=$ROSACCOUNT password=$ROSPASSWD level=p-unlimited
EOF
fi

if [ -n "$VER_6" ]; then
cat >> /mnt/ros/rw/autorun.scr <<EOF
#upgrade
/system package update set channel=upgrade
/system package update check-for-updates once
:delay 3s;
:if ( [/system package update get status] = "New version is available") do={ /system package update install }
EOF
fi

sync
umount /mnt/ros

###release loop device
losetup -d $LOOPDEV
sync

########dd
echo 'dd starting'
echo u > /proc/sysrq-trigger
dd if=/mnt/img/chr.img of=/dev/$DSTDISK bs=1M oflag=sync
echo 'rebooting'
echo b > /proc/sysrq-trigger
