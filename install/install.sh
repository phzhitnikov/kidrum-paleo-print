#!/bin/sh
# Configuration script for paleo-printer

HOSTNAME="paleo-printer"
PACKAGES="samba cups cups-bsd python3-pip"

PRINTER_NAME="HP_LaserJet_M1005"

AddToAutostart() {
	# Check if already added to autostart
	if ! grep -xqFe "$1" /etc/rc.local
	then
		sed -i -e '$i '"$1"'' /etc/rc.local
	fi
}

# Install packages
echo "*** Updating repos & upgrading packages. This may take a while"
apt-get -q update && apt-get -q upgrade -y && apt-get -q update

#FIXME doesnt work properly
echo "*** Installing packages: $PACKAGES"
apt install $PACKAGES -y

echo "*** Changing hostname to $HOSTNAME and turning on VNC. This will require reboot to apply"
raspi-config nonint do_hostname $HOSTNAME
raspi-config nonint do_vnc 1
#TODO change timezone to Europe/Moscow

# Add new SAMBA user and restart service
(echo ""; echo "") | smbpasswd -s -a pi
/etc/init.d/samba restart

# Configure CUPS
usermod -a -G lpadmin pi
cupsctl --remote-any
/etc/init.d/cups restart

# Get driver for HP Deskjet M1005 and build it. Sources are hosted here:
# http://foo2zjs.rkkda.com/foo2zjs.tar.gz
echo "*** Installing HP Deskjet drivers"
tar zxf foo2zjs.tar.gz
cd foo2zjs
make && ./getweb 1005 && make install && make install-hotplug && make cups

echo "*** IMPORTANT! Don't forget to edit [printers] sections in smb.conf!"
#TODO make share folder and printers browserable (smb.conf) - change line in [printers] section
# [printers]
   # comment = All Printers
   # browseable = yes
   # path = /var/spool/samba
   # printable = yes
   # guest ok = yes
   # read only = yes
   # create mask = 0700

echo "*** Adding $PRINTER_NAME to CUPS"
PRINTER_URL=$(lpinfo -v | grep usb | cut -d' ' -f 2)

# Check if printer is plugged in
if [$PRINTER_URL]
then
  # WARNING: lpadmin -P is considered deprecated. It may break script in the future
  # Check manual here: https://www.cups.org/doc/man-lpadmin.html
  lpadmin -p $PRINTER_NAME -v $PRINTER_URL -E -P "/usr/share/cups/model/HP-LaserJet_M1005_MFP.ppd.gz"

  echo "*** Installing script dependencies"
  pip3 install flask
  
  echo "*** Adding python webserver script to autostart"
  AddToAutostart "python3 /home/pi/main.py &"
  
else
  echo "*** Printer $PRINTER_NAME is not found. Did you forget to plug it in or install drivers?"
fi
