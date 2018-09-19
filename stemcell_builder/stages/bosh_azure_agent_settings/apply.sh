#!/usr/bin/env bash

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

if [ $DISTRIB_CODENAME == 'xenial' ]; then
  user_data_path="/var/lib/cloud/instance/user-data.txt"
else
  user_data_path="/var/lib/waagent/CustomData"
fi

# Set SettingsPath but never use it because file_meta_service is avaliable only when the settings file exists.
cat > $chroot/var/vcap/bosh/agent.json <<JSON
{
  "Platform": {
    "Linux": {
      "CreatePartitionIfNoEphemeralDisk": true,
      "DevicePathResolutionType": "scsi",
      "PartitionerType": "parted"
    }
  },
  "Infrastructure": {
    "Settings": {
      "Sources": [
        {
          "Type": "File",
          "MetaDataPath": "",
          "UserDataPath": "$user_data_path",
          "SettingsPath": "$user_data_path"
        }
      ],
      "UseServerName": true,
      "UseRegistry": true
    }
  }
}
JSON
