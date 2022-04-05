#!/bin/bash

rm ./assets/Autounattend.iso

if [[ $OSTYPE == 'darwin'* ]]; then
  hdiutil makehybrid -o ./assets/Autounattend-win2019.iso -hfs -joliet -iso -default-volume-name cidata ./scripts
else
  mkisofs -J -l -R -V cidata -iso-level 4 -o ./assets/Autounattend-win2019.iso ./scripts
fi


scp ./assets/Autounattend-win2019.iso root@pve.cryptable.local:/var/lib/vz/template/iso/