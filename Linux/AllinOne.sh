#!/bin/bash
#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c(){
    echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Saliendo de manera controlada ${endColour}\n"
    exit 0
}
# SUID
curl -k -s -X GET https://gtfobins.github.io/\#+suid | grep -i '/gtfobins/' | grep -i "SUID" | awk '{print $3}' FS="/" > /tmp/vulnerable-suid.txt
for SUID in $(find / -perm -4000 2>/dev/null | awk 'NF{print $NF}' FS="/")
do
	vuln_suid=$(grep -i "^$SUID$" /tmp/vulnerable-suid.txt)
	if [ $? -eq 0 ]; then
		echo -e "${greenColour}\n\t[V] El binario $vuln_suid is vulnerable ${endColour}" | tee List-vulnerable-suid-found.txt
	fi
done
rm -rf /tmp/vulnerable-suid.txt

# Etc path Writable
writable=$(find /etc -writable 2>/dev/null)
echo -e "${greenColour}\n\t[W] La ruta $writable is writable ${endColour}" | tee List-etc-writables.txt

# Process monitoring for search cron
old_process=$(ps -eo command,user)
while true; do
	new_process=$(ps -eo command,user)
	diff <(echo "$old_process") <(echo "$new_process") | grep "[\>\<]" | grep -A 20 -i "cron" | tee List-cron.txt
	old_process=$new_process
done
