#!/bin/bash

if [[ x$1 == x ]]; then
	echo "missing username"
else
	usrn=$1
fi

basedir=/sensor_data/MITRAP-DATA
useradd --gid 1000 -b ${basedir} -m ${usrn}
sudo -u ${usrn} ssh-keygen -q -t rsa -N "" 
cp -p ${basedir}/${usrn}/.ssh/id_rsa.pub ${basedir}/${usrn}/.ssh/authorized_keys
cp ${basedir}/${usrn}/.ssh/id_rsa /home/mitrap/keys/id_rsa_${usrn}
chown mitrap:mitrap /home/mitrap/keys/id_rsa_${usrn}

exit 0

