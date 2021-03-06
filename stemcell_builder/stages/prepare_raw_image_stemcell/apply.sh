#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

pushd $work
rm -f root.img
ln ${stemcell_image_name} root.img
tar zcf stemcell/image root.img
popd
