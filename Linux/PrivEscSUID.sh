#!/bin/bash

# Parameter SUIDFILE with output of 'find / -perm -4000 2>/dev/null' or LinEnum SUID part in machine

# SUID
SUIDFILE=$1

SUID="ab agetty alpine ar aria2c arj arp as ascii-xfr ash aspell atobm awk awk base32 base64 basenc basez bash bridge busybox byebug bzip2 capsh cat chmod choom chown chroot cmp column comm composer cp cpio cpulimit csh csplit csvtool cupsfilter curl cut dash date dd dialog diff dig dmsetup docker dosbox dvips ed ed efax emacs env eqn expand expect file find fish flock fmt fold gawk gawk gcore gdb genie genisoimage gimp ginsh git grep gtester gzip hd head hexdump highlight hping3 iconv iftop install ionice ip ispell jjs join jq jrunscript ksh ksshell kubectl latex ld.so ldconfig less lftp logsave look lua lua lualatex luatex make mawk mawk more mosquitto msgattrib msgcat msgconv msgfilter msgmerge msguniq multitime mv mysql nano nasm nawk nawk nc nft nice nl nm nmap nmap node nohup octave od openssl openvpn paste pdflatex pdftex perf perl pg php pic pico pidstat pr pry psftp ptx python rake readelf restic rev rlwrap rpm rpmdb rpmquery rpmverify rsync run-parts rview rview rvim rvim sash scanmem scp scrot sed setarch setfacl shuf slsh socat soelim sort sqlite3 sqlite3 ss ssh-keygen ssh-keyscan sshpass start-stop-daemon stdbuf strace strings sysctl systemctl tac tail tar taskset tasksh tbl tclsh tee telnet tex tftp tic time timeout tmate troff ul unexpand uniq unshare unzip update-alternatives uudecode uuencode view view vigr vim vim vimdiff vimdiff vipw watch watch wc wget whiptail xargs xdotool xelatex xetex xmodmap xmore xxd xz yash zip zsh zsoelim "

# If there is internet download suid, if not use local
SUID_INTERNET=`curl -k -s -X GET https://gtfobins.github.io/\#+suid`
if [ $? -eq 0 ]; then
    SUID=`echo "$SUID_INTERNET" | grep -i '/gtfobins/' | grep -i "SUID" | awk '{print $3}' FS="/"`
else
    echo "Offline"
fi

echo "$SUID" > /tmp/vulnerable-suid.txt

for SUID in $(cat $SUIDFILE | awk 'NF{print $NF}' FS="/")
do
        vuln_suid=$(grep -i "^$SUID$" /tmp/vulnerable-suid.txt)
        if [ $? -eq 0 ]; then
                echo -e "${greenColour}\\n[SUID] Binary $vuln_suid is vulnerable ${endColour}" | tee List-vulnerable-suid-found.txt
        fi
done
rm -rf /tmp/vulnerable-suid.txt
