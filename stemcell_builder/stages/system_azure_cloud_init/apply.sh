#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

if [ "${os_type}" == "ubuntu" ]
then
  run_in_chroot $chroot "
    apt-get update # check update?
    apt-get install -y cloud-init
  "
  cp -f $dir/assets/etc/cloud/cloud.cfg $chroot/etc/cloud/cloud.cfg
  #cp -f $dir/assets/etc/cloud/cloud.cfg.d/05_logging.cfg $chroot/etc/cloud/cloud.cfg.d/05_logging.cfg
  #cp -f $dir/assets/etc/cloud/cloud.cfg.d/90-azure.cfg $chroot/etc/cloud/cloud.cfg.d/90-azure.cfg
  #cp -f $dir/assets/etc/cloud/cloud.cfg.d/91_walinuxagent.cfg $chroot/etc/cloud/cloud.cfg.d/91_walinuxagent.cfg
  #cp -f $dir/assets/etc/rsyslog.d/21-cloudinit.conf $chroot/etc/rsyslog.d/21-cloudinit.conf
elif [ "${os_type}" == "rhel" -o "${os_type}" == "centos" ]
then
  run_in_chroot $chroot "
    yum check-update cloud-init -y
    yum install cloud-init -y
  "
  #cp -f $dir/assets/etc/rsyslog.d/21-cloudinit.conf $chroot/etc/rsyslog.d/21-cloudinit.conf
else
  echo "Unknown OS '${os_type}', exiting"
  exit 2
fi

run_in_chroot $chroot "
   #cloud-init init --local
   #rm -rf /var/lib/cloud/instances/*
   #touch /var/log/cloudinit.log
   #chown syslog:syslog /var/log/cloudinit.log
   #chmod 600 /var/log/cloudinit.log
"
#cp -f $dir/assets/var/lib/cloud/scripts/per-once/firstboot.sh $chroot/var/lib/cloud/scripts/per-once/firstboot.sh #Not need to run everytime

#TODO: test centos
