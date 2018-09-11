#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

packages="python python-pyasn1 python-setuptools"
pkg_mgr install $packages

wala_release=2.2.25
wala_expected_sha1=8fb9ef0558c11b70b48188fb5afd53eadc321fac

curl -L https://github.com/Azure/WALinuxAgent/archive/v${wala_release}.tar.gz > /tmp/wala.tar.gz
sha1=$(cat /tmp/wala.tar.gz | openssl dgst -sha1  | awk 'BEGIN {FS="="}; {gsub(/ /,"",$2); print $2}')
if [ "${sha1}" != "${wala_expected_sha1}" ]; then
  echo "SHA1 of downloaded v${wala_release}.tar.gz ${sha1} does not match expected SHA1 ${wala_expected_sha1}."
  rm -f /tmp/wala.tar.gz
  exit 1
fi

mv -f /tmp/wala.tar.gz $chroot/tmp/wala.tar.gz

run_in_chroot $chroot "
  cd /tmp/
  tar zxvf wala.tar.gz
  cd WALinuxAgent-${wala_release}
  sudo python setup.py install --skip-data-files
  cp bin/waagent* /usr/sbin/
  chmod 0755 /usr/sbin/waagent*
  cd /tmp/
  sudo rm -fr WALinuxAgent-${wala_release}
  rm wala.tar.gz
"
cp -f $dir/assets/etc/waagent.conf $chroot/etc/waagent.conf

if [ ${DISTRIB_CODENAME} == 'trusty' ]; then
  cp -a $dir/assets/runit/waagent $chroot/etc/sv/waagent
  # Set up waagent with runit
  run_in_chroot $chroot "
  chmod +x /etc/sv/waagent/run
  ln -s /etc/sv/waagent /etc/service/waagent
  "
else
  cp -f $dir/assets/etc/walinuxagent.service $chroot/lib/systemd/system/walinuxagent.service
  chmod 0755 $chroot/lib/systemd/system/walinuxagent.service
  run_in_chroot $chroot "systemctl enable walinuxagent.service"
fi

cat > $chroot/etc/logrotate.d/waagent <<EOS
/var/log/waagent.log {
    monthly
    rotate 6
    notifempty
    missingok
}
EOS

# cloud-init
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

run_in_chroot $chroot "
  sed -i 's/Provisioning.Enabled=y/Provisioning.Enabled=n/g' /etc/waagent.conf
  sed -i 's/Provisioning.UseCloudInit=n/Provisioning.UseCloudInit=y/g' /etc/waagent.conf
  sed -i 's/ResourceDisk.Format=y/ResourceDisk.Format=n/g' /etc/waagent.conf
  sed -i 's/ResourceDisk.EnableSwap=y/ResourceDisk.EnableSwap=n/g' /etc/waagent.conf
"

cp -f $dir/assets/etc/cloud/cloud.cfg $chroot/etc/cloud/cloud.cfg
cp -f $dir/assets/etc/cloud/cloud.cfg.d/90-azure.cfg $chroot/etc/cloud/cloud.cfg.d/90-azure.cfg
cp -f $dir/assets/etc/cloud/cloud.cfg.d/91_walinuxagent.cfg $chroot/etc/cloud/cloud.cfg.d/91_walinuxagent.cfg

run_in_chroot $chroot "
  cloud-init init --local
  rm -rf /var/lib/cloud/instances/* 
  rm -rf /var/log/cloud-init*
"
cp -f $dir/assets/var/lib/cloud/scripts/per-once/firstboot.sh $chroot/var/lib/cloud/scripts/per-once/firstboot.sh #Not need to run everytime
