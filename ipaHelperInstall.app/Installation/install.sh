#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
error=N

if [ ! -d /usr/local/bin ]; then
    sudo mkdir /usr/local/bin
fi

sudo cp "$dir/ipaHelper" /usr/local/bin/
if [ $? != 0 ]; then
    error=Y
    echo "Error copying script"
fi

sudo cp "$dir/ipaHelper.1" /usr/share/man/man1/
if [ $? != 0 ]; then
    error=Y
    echo "Error copying man page"
fi
if [ ! -d ~/Library/Quicklook ]; then
    mkdir ~/Library/Quicklook
fi
if [ -d ~/Library/Quicklook/ipaHelper.qlgenerator ]; then
    sudo rm -rf ~/Library/Quicklook/ipaHelper.qlgenerator
fi
sudo cp -r "$dir/ipaHelper.qlgenerator" ~/Library/Quicklook/ipaHelper.qlgenerator
if [ $? != 0 ]; then
    error=Y
    echo "Error copying quicklook generator"
fi
if [ -d ~/Library/Services/Resign.workflow ]; then
    sudo rm -rf ~/Library/Services/Resign.workflow
fi
sudo cp -r "$dir/Resign.workflow/" ~/Library/Services/Resign.workflow
if [ $? != 0 ]; then
    error=Y
    echo "Error copying Resign service"
fi

if [ "$error" = "N" ]; then
    echo "Installation Successful"
fi
#exit 0
