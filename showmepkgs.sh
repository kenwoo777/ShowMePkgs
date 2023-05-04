#!/bin/bash


# ShowMePkgs.sh by ken woo v.1.0 copyleft
# code is from internet and forgot where comes and rearranged as well.
# Get the details of specific packages, and showing all activities of ever used packages as well.
# only tested in Ubuntu. (might for Ubuntu only?).
# usage: showmepkgs.sh [pkgname(s)]


pkgtmp=$( mktemp -t pkgtmp.XXXXXXXX )
if [ $? -ne 0 ]; then exit 1; fi;


nlogs=$( ls -l /var/log/dpkg.log.*.gz | wc -l )
nlogs=$(( $nlogs + 1 ))

nulogs=$( ls -l /var/log/dpkg.log.* | wc -l )
nulogs=$(( $nulogs + 1 - $nlogs ))


# first append current log

cat /var/log/dpkg.log | grep "\ install\ " >> "$pkgtmp"
cat /var/log/dpkg.log | grep "\ remove\ " >> "$pkgtmp"
cat /var/log/dpkg.log | grep "\ upgrade\ " >> "$pkgtmp"


# next append all info from unarchived logs(larger number is older)

i=1
while [ $i -le $nulogs ]; do

    if [ -e /var/log/dpkg.log.$i ]; then
        cat /var/log/dpkg.log.$i | grep "\ install\ " >> "$pkgtmp"
        cat /var/log/dpkg.log.$i | grep "\ remove\ " >> "$pkgtmp"
        cat /var/log/dpkg.log.$i | grep "\ upgrade\ " >> "$pkgtmp"
    fi

i=$(( $i+1 ))
done


# next append all info from archived logs

i=2
while [ $i -le $nlogs ]; do

    if [ -e /var/log/dpkg.log.$i.gz ]; then
        zcat /var/log/dpkg.log.$i.gz | grep "\ install\ " >> "$pkgtmp"
        zcat /var/log/dpkg.log.$i.gz | grep "\ remove\ " >> "$pkgtmp"
        zcat /var/log/dpkg.log.$i.gz | grep "\ upgrade\ " >> "$pkgtmp"
    fi

i=$(( $i+1 ))
done


# sort text file by date

sort -n "$pkgtmp" | cat -n
echo -e "\n\n\n";


# Now displaying the installation details of packages passed as arguments

for pkg in $@; do
    echo -e "\n--------------------- Installation Details of $pkg ---------------------\n"

    cat "$pkgtmp" | grep -i --color "$pkg"

    echo -e "\n\n";

    cat "$pkgtmp" | grep -i "install.*$pkg" | tr -s [:blank:] " " |\
        cut -d' ' -f4 | sed -n 's/\([^:]*\).*/\1/p' | sort -u | xargs apt-cache show

        [[ $? -ne 0 ]] && apt list | grep "$pkg" -i --color

    echo;
done


rm "$pkgtmp"


# end of sh
