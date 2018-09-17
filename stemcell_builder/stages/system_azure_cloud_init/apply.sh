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
elif [ "${os_type}" == "rhel" -o "${os_type}" == "centos" ]
then
  run_in_chroot $chroot "
    sudo yum install -y cloud-init
    sudo yum check-update cloud-init -y
    sudo yum install cloud-init -y
  "
else
  echo "Unknown OS '${os_type}', exiting"
  exit 2
fi

cp -f $dir/assets/etc/cloud/cloud.cfg $chroot/etc/cloud/cloud.cfg
cp -f $dir/assets/etc/cloud/cloud.cfg.d/90-azure.cfg $chroot/etc/cloud/cloud.cfg.d/90-azure.cfg
cp -f $dir/assets/etc/cloud/cloud.cfg.d/91_walinuxagent.cfg $chroot/etc/cloud/cloud.cfg.d/91_walinuxagent.cfg

run_in_chroot $chroot "
  cloud-init init --local
  rm -rf /var/lib/cloud/instances/* 
  rm -rf /var/log/cloud-init*
"
cp -f $dir/assets/var/lib/cloud/scripts/per-once/firstboot.sh $chroot/var/lib/cloud/scripts/per-once/firstboot.sh #Not need to run everytime

#TODO: test centos
