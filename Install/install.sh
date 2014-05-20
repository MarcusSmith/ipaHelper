#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp "$dir/ipaHelper" /usr/bin/
sudo cp "$dir/ipaHelper.1" /usr/share/man/man1/
cp "$dir/ipaHelper.qlgenerator" ~/Library/Quicklook
cp "$dir/Resign.workflow" ~/Library/Services

#exit 0
