#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

if [ $DISTRIB_CODENAME == 'xenial' ]; then
  run_in_chroot $chroot "
    # install cloud-init
    apt-get update
    apt-get install -y cloud-init

    # use cloud-init for provision instead of waagent
    sed -i 's/Provisioning.Enabled=y/Provisioning.Enabled=n/g' /etc/waagent.conf
    sed -i 's/Provisioning.UseCloudInit=n/Provisioning.UseCloudInit=y/g' /etc/waagent.conf
  "
  cp -f $dir/assets/etc/cloud/cloud.cfg $chroot/etc/cloud/cloud.cfg
  #cp -f $dir/assets/etc/cloud/cloud.cfg.d/05_logging.cfg $chroot/etc/cloud/cloud.cfg.d/05_logging.cfg
  #cp -f $dir/assets/etc/cloud/cloud.cfg.d/90-azure.cfg $chroot/etc/cloud/cloud.cfg.d/90-azure.cfg
  #cp -f $dir/assets/etc/cloud/cloud.cfg.d/91_walinuxagent.cfg $chroot/etc/cloud/cloud.cfg.d/91_walinuxagent.cfg

  # V TODO
  cp -f $dir/assets/etc/rsyslog.d/21-cloudinit.conf $chroot/etc/rsyslog.d/21-cloudinit.conf
  run_in_chroot $chroot "
    touch /var/log/cloudinit.log
    chown syslog:syslog /var/log/cloudinit.log
    chmod 600 /var/log/cloudinit.log
  "
else
  echo "Ignore cloud-init on ${DISTRIB_CODENAME}..."
fi
