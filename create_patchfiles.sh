#!/bin/bash
root=$(pwd)
for dir in CE1* EE1*
do
	echo 'Reading directory' "$dir"
	cd "$root"/"$dir"
	mkdir patchfiles
    for i in *.sh
    do
        sed '0,/^__PATCHFILE_FOLLOWS__$/d' "$i" > patchfiles/"${i%.sh}.patch"
    done
done
