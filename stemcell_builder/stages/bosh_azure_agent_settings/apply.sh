#!/usr/bin/env bash

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

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
          "UserDataPath": "/var/lib/cloudinit/CustomData",
          "SettingsPath": "/var/lib/cloudinit/CustomData"
        }
      ],
      "UseServerName": true,
      "UseRegistry": true
    }
  }
}
JSON
