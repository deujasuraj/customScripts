#!/bin/bash
tmp=tmp
ARMTCPkg='arm-2013.11-24-arm-none-eabi-i686-pc-linux-gnu.tar.bz2'
ARMToolChain='https://sourcery.mentor.com/public/gnu_toolchain/'\
'arm-none-eabi/'$ARMTCPkg

OpenOCDPkg='openocd-0.7.0.tar.bz2'
OpenOCD='http://sourceforge.net/projects/openocd/files/'\
'openocd/0.7.0/'$OpenOCDPkg

StLinkSrc='https://github.com/texane/stlink.git'

EclipsePkg='eclipse-standard-kepler-SR1-linux-gtk-x86_64.tar.gz'
EclipseKeplerSrc='http://www.gtlib.gatech.edu/pub/eclipse/'\
'technology/epp/downloads/release/kepler/SR1/'$EclipsePkg

install_arm_tool_chain(){
	test -d temp || mkdir tmp
	cd $tmp
	wget $ARMToolChain
	if [ $? -ne 0 ]
	then
		echo "Could not download file";
		exit	
	fi
	mkdir /opt/arm
	chown `whoami`:users -R /opt/arm
	tar -xjvf $ARMTCPkg -C /opt/arm/
	
	ln -s /opt/arm/arm-2013.11 /opt/arm/toolchain
	echo 'export PATH=$PATH:/opt/arm/toolchain/bin' | \
tee /etc/profile.d/arm-toolchain.sh
	
	chmod +x /etc/profile.d/arm-toolchain.sh
	for i in /opt/arm/arm-2013.11/share/doc/arm-arm-none-eabi/man/man1/*;
	do
		install -D $i /usr/local/share/man/man1/$i
	done
} 

install_openOCD(){
	test -d tmp || mkdir tmp
	cd $tmp
	wget $OpenOCD
	if [ $? -ne 0 ]
	then
		echo "Could not download file";
		exit
	fi	
	tar -xjvf $OpenOCDPkg -C /opt/arm
	cd /opt/arm/openocd-0.7.0
	./configure --enable-stlink
	if [$? -ne 0]
	then
		echo "Error: see error"
	fi
	make -j4
	make install
}

install_stlink(){
	test -d tmp || mkdir tmp
	cd $tmp
	git clone $StLinkSrc
	cd stlink
	./autogen.sh
	./configure
	make
	make install
	cp *.rules /etc/udev/rules.d/
	udevadm control --reload-rules
	# Make sure to copy st-tool binary to /usr/loca/bin.
	# It is not in here.
}

install_qstlink2(){
	add-apt-repository ppa:mobyfab/qstlink2
	(exec apt-get update) && (exec apt-get install qstlink2)
}

install_eclipse(){
	test -d tmp || mkdir tmp
	cd $tmp
	wget $EclipseKeplerSrc
	tar -xzvf $EclipsePkg -C /opt/
	sudo chown -R `whoami`:users /opt/eclipse
}

install_devtools(){
	sudo apt-get install apt-get install build-essential subversion
	sudo apt-get install git htop minicom openjdk-7jdk qt4-dev-tools
	sudo apt-get install qt4-qmake libqt4-gui qt4-designer qtcreator
	sudo apt-get install libusb-dev libusb-1.0.0-dev autoconf
	sudo apt-get install automake pkg-config libtool
}

case "$1" in
"armtoolchain")
	install_arm_tool_chain
	;;
"openocd")
	install_openOCD
	;;
"stlink")
	install_stlink
	;;
"qstlink2")
	install_qstlink2
	;;
"eclipse")
	install_eclipse
	;;
"devtools")
	install_devtools
	;;
*) 
	echo 'Usage: '
	echo 'Flags:		Description'
	echo 'armtoolchain:	Install the armtool chain'
	echo 'openocd:	Install openocd'
	echo 'stlink:		Install stlink'
	echo 'qstlink2:	Install QSTLink2'
	echo 'eclipse:	Install eclipse'
	echo 'devtools:	Dev tools'
	;;
esac
