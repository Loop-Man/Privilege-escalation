#!/bin/bash
#author		: Manuel López Torrecillas & Raúl Calvo Laorden
#description: Script para lanzar los escaneos mínimos de reconocimiento de TII (interna)
#use: sudo bash <nombre-script> $CIDR $INTERFACE $FOLDER


# TODO
# - Fix errors hosts.txt files (vuln, etc, witch shows all IPs instead vuln only)
# - If imput its not all verify if its not null
# - Hosts file delete if empty

# - Option to target IP or File of IPs from arp o other source

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

# Lo primero será crear la función ctrl_c() para crear una salida controlada del script
function ctrl_c() {
	# El -e para que no introduzca el echo el new line y tengamos que ponerlo nosotros manualmente (\n)
	echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Saliendo de manera controlada${endColour}\n"
	exit 0
}

# If verbose is True show output to terminal and save it to $0.log
# Example: printIfVerbose nmap -v ; if VERBOSE=1 it saves the output to file and show in terminal
# 			If its 0 not show output
function printIfVerbose () {
    if [[ $VERBOSE -eq 1 ]]; then
		date | tee -a "$FOLDER/script.log"
		echo "$@" | tee -a "$FOLDER/script.log"
        "$@" | tee -a "$FOLDER/script.log"
    else 
		date >> "$FOLDER/script.log"
		echo "$@" >> "$FOLDER/script.log"
    	"$@" >> "$FOLDER/script.log"
    fi
}

function usage()
{
    echo "Usage: $0 ([-t TARGET CIDR]|[-r TARGET FILE]) [-f FOLDER] "
    echo -e "\t -t TARGET: CIDR"
    echo -e "\t -r FILE: TARGET FILE"
    echo -e "\t -f FOLDER"
    echo -e "\t -i INTERFACE: Interface to Responder"
    echo -e "\t -H: Heavy commands"
    echo -e "\t -F: Force relunch all"
    echo -e "\t -v: verbose mode"
    echo -e "\t -h: Print this message"

    exit 2
}

################################ Arguments ################################


TARGET=''
TARGETFILE=''
FOLDER=''
INTERFACE=''
VERBOSE=0
HEAVY=false
FORCE=false

while getopts ':t:r:f:iHFvh?' option
do
    case "${option}"
        in
        t) TARGET=${OPTARG};;
        r) TARGETFILE=${OPTARG};;
        f) FOLDER=${OPTARG};;
        i) INTERFACE=${OPTARG};;
        F) FORCE=true;;
        v) VERBOSE=1;;
        H) HEAVY=true;;
        h|?) usage;;
        *) echo "Invalid Option: -$OPTARG" 1>&2 ; usage;;
    esac
done

echo $TARGET
echo $FOLDER

if [ -z "$TARGET" && -z "$TARGETFILE" ] ; then
    echo "No IP or CIDR argument supplied with -t or file using -r"
	usage
	exit 1
fi

if [ -z "$FOLDER" ] ; then
    echo "No FOLDER argument supplied"
	usage
	exit 2
fi

# Remove after check
IP=$TARGET

# IF its target, save to temp file and set TARGETFILE
if [ ! -z "$TARGET" ] ; then
    TARGETFILE='/tmp/TARGETFILE.tmp'
    echo "$TARGET" > /tmp/TARGETFILE.tmp
fi


# Create client folder
if [ ! -d "$FOLDER" ]; then
	mkdir "$FOLDER"
fi

#Starting
printIfVerbose echo '
Starting scan $TARGET 
	TARGET: '$TARGET' 
	TARGETFILE: '$TARGETFILE' 
	FOLDER: '$FOLDER' 
	INTERFACE: '$INTERFACE'
	VERBOSE: '$VERBOSE'
	HEAVY: '$HEAVY'
	FORCE: '$FORCE'
'
# create folder empty
mkdir "$FOLDER/empty/"

################################ rpc ################################
echo "#### RPC ####"
## Reconocimiento
echo -n "Recon "
FILEAUX="$FOLDER/rpc-Open-enum"
if [ ! -f "$FILEAUX.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 111 -T4 --open --script 'rpcinfo,rpc-grind' -oN "$FILEAUX.txt" -iL $TARGETFILE 
	grep 'Nmap scan report for ' "$FILEAUX.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILEAUX-hosts.txt"
	for IP in `cat  "$FILEAUX-hosts.txt"` ; do
		enum4linux -a $IP
	done >  "$FILEAUX-enum4linux.txt"
fi

echo " ✓"

################################ SMB ################################
echo "#### SMB ####"
## Reconocimiento
echo -n "Recon "
#masscan $TARGET -p 139,445 | awk 'NF{print $NF}' > $FOLDER/SMB-Open.txt
FILESMBOPEN="$FOLDER/SMB-Open"
if [ ! -f "$FILESMBOPEN.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 139,445 -T4 --open -oN "$FILESMBOPEN.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESMBOPEN.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESMBOPEN-hosts.txt"
fi
echo " ✓"
## Version
#nmap -v -Pn -sV -p 139,445 -T4 --script smb-os-discovery -oN "$FOLDER/SMB-OS-Discovery.txt" -iL "$FOLDER/SMB-Open.txt"
#nmap -v -Pn -n --disable-arp -sV -p 139,445 -T4 --open --script smb-os-discovery -oN "$FOLDER/SMB-OS-Discovery.txt" -iL $TARGETFILE

## Enumeración de carpetas
echo -n "Folders "
#nmap -v -Pn -sV -p 139,445 -T4 --script smb-enum-shares -oN "$FOLDER/SMB-Shares.txt" -iL "$FOLDER/SMB-Open.txt"
FILESMBFOLDERS="$FOLDER/SMB-folders"
if [ ! -f "$FILESMBFOLDERS.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 139,445 -T4 --open --script smb-os-discovery,smb-enum-shares -oN "$FILESMBFOLDERS.txt" -iL "$FILESMBOPEN-hosts.txt"
	grep 'Nmap scan report for ' "$FILESMBFOLDERS.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESMBFOLDERS-hosts.txt"
fi
echo " ✓"

## Netapi (Windows XP y Windows server 2003)
echo -n "Netapi "
## Metasploit exploit: exploit/windows/smb/ms08_067_netapi
#nmap -v -Pn -sV -p 139,445 -T4 --script smb-vuln-ms08-067 -oN "$FOLDER/SMB-Netapi.txt" -iL "$FOLDER/SMB-Open.txt"
FILESMBNETAPI="$FOLDER/SMB-Netapi"
if [ ! -f "$FILESMBNetapi.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 139,445 -T4 --open --script smb-vuln-ms08-067 -oN "$FILESMBNetapi.txt" -iL "$FILESMBOPEN-hosts.txt" 
	grep "VULNERABLE:" -B 10 "$FILESMBNetapi.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESMBNetapi-hosts.txt"
fi
echo " ✓"

## Eternalblue ms17-010 (Windows 7 y Windows Server 2008)
echo -n "Eternalblue "
## Metasploit check: metasploit:  auxiliary(scanner/smb/smb_ms17_010)
## Metasploit exploit: metasploit: windows/smb/ms17_010_psexec)
#nmap -v -Pn -sV -p 139,445 -T4 --script smb-vuln-ms17-010 -oN "$FOLDER/SMB-Eternalblue.txt" -iL "$FOLDER/SMB-Open.txt"
FILESMBEternalblue="$FOLDER/SMB-Eternalblue"
if [ ! -f "$FILESMBEternalblue.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 139,445 -T4 --open --script smb-vuln-ms17-010 -oN  "$FILESMBEternalblue.txt" -iL "$FILESMBOPEN-hosts.txt"
	#grep 'Nmap scan report for '   | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"
	grep 'State: VULNERABLE' -B 15 "$FILESMBEternalblue.txt" | grep 'Nmap scan report for ' | awk '{print $5}' >  "$FILESMBEternalblue-hosts.txt"

fi
echo " ✓"

## EternalRed aka Sambacry CVE-2017-7494 (versiones de samba >3.5)
echo -n "EternalRed "
## Manual exploit: https://github.com/opsxcq/exploit-CVE-2017-7494
## ./exploit.py -t localhost -e libbindshell-samba.so -s data -r /data/libbindshell-samba.so -u sambacry -p nosambanocry -P 6699
## Metasploit exploit: exploit/linux/samba/is_known_pipename
FILESMBEternalred="$FOLDER/SMB-Eternalred"
if [ ! -f "$FILESMBEternalred.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -p 139,445 --script smb-vuln-cve-2017-7494 --script-args smb-vuln-cve-2017-7494.check-version -oN "$FILESMBEternalred.txt" -iL "$FILESMBOPEN-hosts.txt"
	grep "VULNERABLE:" -B 12 "$FILESMBEternalred.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESMBEternalred-hosts.txt"
fi
echo " ✓"

##SMBGhost - SMBv3 (CVE-2020-0796)
echo -n "SMBGhost "
if [ ! -f "/usr/share/nmap/scripts/cve-2020-0796.nse" ]; then
	wget https://raw.githubusercontent.com/psc4re/NSE-scripts/master/cve-2020-0796.nse -P /usr/share/nmap/scripts/
	nmap -v --script-updatedb
fi
#nmap -v -Pn -p 445 --script cve-2020-0796 -oN "$FOLDER/SMB-Ghost.txt" -iL "$FOLDER/SMB-Open.txt"
FILESMBGhost="$FOLDER/SMB-Ghost"
if [ ! -f "$FILESMBGhost.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 445 -T4 --open --script cve-2020-0796 -oN "$FILESMBGhost.txt" -iL "$FILESMBOPEN-hosts.txt"
	grep 'Nmap scan report for ' "$FILESMBGhost.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESMBGhost-hosts.txt"
fi
echo " ✓"

## Enum
#nmap -v -Pn -n --disable-arp -sV -p 139,445 -T4 --open --script 'smb-enum-*,smb-os-discovery,smb-system-info,smb-vuln-*' -oN "$FOLDER/SMB-Enum.txt" -iL $TARGETFILE

## RunFinger
if [ ! -f "/usr/share/responder/tools/RunFinger.py" ]; then
    echo -n "RunFinger "
	for IP in $(cat "$FILESMBOPEN-hosts.txt"); do
    	echo $IP
		printIfVerbose /usr/share/responder/tools/RunFinger.py -i $IP | tee -a "$FOLDER/SMB-runFinger.log"
	done
fi

################################ RDP ################################
echo "#### RDP ####"
## Reconocimiento
echo -n "Recon "
#nmap -v -sV -p 3389 -T4 --open -oN "$FOLDER/RDP-Open.txt" -iL $TARGETFILE
## No meterle awk ya que luego rdpscan lo pilla con este formato.
# masscan $TARGET -p 3389 > "$FOLDER/RDP-Open.txt"
FILESRDPOpen="$FOLDER/RDP-Open"
if [ ! -f "$FILESRDPOpen.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 3389 -T4 --open -oN "$FILESRDPOpen.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESRDPOpen.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESRDPOpen-hosts.txt"
fi
echo " ✓"

## Acceder mediante rdesktop en todos los abiertos detectados para obtener usuarios cacheados.
#rdesktop $TARGET
#xfreerdp $TARGET

##BlueKeep
echo -n "BlueKeep (rdpscan) "
##Metasploit check: auxiliary/scanner/rdp/cve_2019_0708_bluekeep
##Metasploit exploit: exploit/windows/rdp/cve_2019_0708_bluekeep_rce
## El exploit sólo funciona para Windows 7 SP1 y Windows Server 2008 R2 (6.1.7601 x64)
##https://github.com/robertdavidgraham/rdpscan

## Rdpscan
FILESRDPScan="$FOLDER/RDP-BlueKeep"
if [ ! -f "$FILESRDPScan.txt" ] || [ $FORCE  = true ]; then
	if [ ! -d "/opt/rdpscan" ]; then
		apt install libssl-dev -y
		apt install build-essential -y
		git clone https://github.com/robertdavidgraham/rdpscan.git /opt/rdpscan
		gcc /opt/rdpscan/src/*.c -lssl -lcrypto -o /opt/rdpscan/rdpscan
	fi

	/opt/rdpscan/rdpscan --file "$FILESRDPOpen-hosts.txt" --workers 10000 > "$FILESRDPScan.txt"
	grep 'VULNERABLE' "$FILESRDPScan.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESRDPScan-hosts.txt"
fi
echo " ✓"

## Enumeración
echo -n "Enum "
FILESRDPEnum="$FOLDER/RDP-Enum"
if [ ! -f "$FILESRDPEnum.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 3389 -T4 --open --script 'rdp-*' -oN "$FILESRDPEnum.txt" -iL "$FILESRDPOpen-hosts.txt"
fi
echo " ✓"

## RDP Captures
echo -n "Captures (scrying) "
if command -v scrying &>/dev/null; then
	mkdir "$FOLDER/scryingRDP"
	scrying --threads 2 --output "$FOLDER/scryingRDP" --file "$FILESRDPOpen-hosts.txt" --mode rdp
else
	echo -n "Skipping RDP Capture: scrying is not installed "
fi
echo " ✓"

################################ BBDD ################################
echo "#### BBDD ####"
##Mysql
echo -n "MYSQL "
FILESBBDDmysql="$FOLDER/BBDD-mysql"
if [ ! -f "$FILESBBDDmysql.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 3306 -T4 --open --script 'mysql-enum,mysql-users,mysql-databases,mysql-dump-hashes,mysql-variables' -oN "$FILESBBDDmysql.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESBBDDmysql.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESBBDDmysql-hosts.txt"
fi
echo " ✓"

##MSSQL
echo -n "MSSQL "
##comprobar si tiene habilitado el proceso xp_cmdshell. Permite ejecución de comandos como system
FILESBBDDmssql="$FOLDER/BBDD-mssql"
if [ ! -f "$FILESBBDDmssql.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 1433 -T4 --open --script 'ms-sql-empty-password,ms-sql-info' -oN "$FILESBBDDmssql.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESBBDDmssql.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESBBDDmssql-hosts.txt"
fi
echo " ✓"

##Mongodb
echo -n "MONGODB "
##Probar si hay NULL Session
FILESBBDDmongodb="$FOLDER/BBDD-mongodb"
if [ ! -f "$FILESBBDDmongodb.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 27017 -T4 --open -oN "$FILESBBDDmongodb.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESBBDDmongodb.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESBBDDmongodb-hosts.txt"
fi
echo " ✓"

##Oracle
echo -n "ORACLE "
FILESBBDDoracle="$FOLDER/BBDD-oracle"
if [ ! -f "$FILESBBDDoracle.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 1521 -T4 --open --script 'oracle-sid-brute,oracle-tns-version' -oN "$FILESBBDDoracle.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESBBDDoracle.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESBBDDoracle-hosts.txt"
fi
echo " ✓"

##PostgreSQL
echo -n "PostgresSQL "
FILESBBDDpostgresql="$FOLDER/BBDD-postgresql"
if [ ! -f "$FILESBBDDpostgresql.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 5432 -T4 --open -oN "$FILESBBDDpostgresql.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESBBDDpostgresql.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESBBDDpostgresql-hosts.txt"
fi
echo " ✓"

################################ WEB ################################
echo "#### WEB ####"
## Reconocimiento
echo -n "Recon "
FILESWEBenum="$FOLDER/web-enum"
if [ ! -f "$FILESWEBenum.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 80,443,8080,8443 -T4 --open --script 'http-enum,http-config-backup,http-vhosts,http-drupal-enum,http-wordpress-enum' -oN "$FILESWEBenum.txt" -oX "$FILESWEBenum.xml" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESWEBenum.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESWEBenum-hosts.txt"
fi
echo " ✓"

# HTTP Captures
echo -n "Aquatone Screenshot "
if [ ! -f "/opt/aquatone/aquatone" ]; then
	sudo apt install chromium jq -y
	sudo mkdir /opt/aquatone
	URL=$(curl -s "https://api.github.com/repos/michenriksen/aquatone/releases/latest" | jq '.' | grep browser_download_url | grep linux_amd64 | awk -F'"' '{print $4}')
	sudo wget $URL -O /opt/aquatone/aquatone.zip
	sudo unzip -j /opt/aquatone/aquatone.zip -d /opt/aquatone/
fi

mkdir "$FOLDER/aquatoneWeb/"
cat "$FILESWEBenum.xml" | /opt/aquatone/aquatone -nmap -out "$FOLDER/aquatoneWeb/" >> "$FOLDER/aquatoneWeb.log"
echo " ✓"

##Shellshock
echo -n "Shellshock "
PATHS=("/cgi-bin/admin.cgi" "/cgi-bin/bin" "/cgi-bin/status" "/cgi-bin/test.csgi")
FILESshellshock=$FOLDER'/shellshock-vuln'
if [ ! -f "$FILESshellshock.txt" ] || [ $FORCE = true ]; then
	for P in $PATHS; do
		printIfVerbose nmap -v -Pn -n -p 80,443,8080,8443 --script=http-shellshock --script-args uri=$P --append-output -oN "$FILESshellshock.txt" -iL "$FILESWEBenum-hosts.txt"
	done
	grep 'VULNERABLE:' "$FILESshellshock.txt" -B 6 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESshellshock-hosts.txt"
fi
echo " ✓"

################################ VNC ################################
echo "#### VNC ####"
## Reconocimiento
echo -n "Recon "
FILESVNCOpen="$FOLDER/VNC-Open"
if [ ! -f "$FILESVNCOpen.txt" ] || [ $FORCE = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 5800,5801,5900,5901 -T4 --open --script 'vnc-info,realvnc-auth-bypass' -oN "$FILESVNCOpen.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESVNCOpen.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESVNCOpen-hosts.txt"
fi
echo " ✓"

## VPN Captures
echo -n "Catupres (scrying) "
if command -v scrying &>/dev/null; then
    mkdir "$FOLDER/scryingVNC"
	scrying --threads 2 --output "$FOLDER/scryingVNC" --file "$FILESVNCOpen-hosts.txt" --mode vnc
else
	echo -n "Skipping VNC Capture: scrying is not installed "
fi
echo " ✓"

################################ DOCKER API ################################
echo "#### Docker API ####"
## Recon
echo -n "Recon "
FILESdockerAPI="$FOLDER/docker-API"
if [ ! -f "$FILESdockerAPI.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 2375-2376 -T4 --open -oN "$FILESdockerAPI.txt" -iL $TARGETFILE
	cat "$FILESdockerAPI.txt" | grep 'Nmap scan report for ' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESdockerAPI-Open-hosts.txt"
fi
echo " ✓"

################################ LDAP ################################
echo "#### LDAP ####"
## Reconocimiento
echo -n "Recon "
FILESLDAPOpen="$FOLDER/LDAP-Open"
if [ ! -f "$FILESLDAPOpen.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 389 -T4 --open -oN "$FILESLDAPOpen.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESLDAPOpen.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESLDAPOpen-hosts.txt"
fi
echo " ✓"

################################ FTP ################################
echo "#### FTP ####"
## Reconocimiento
echo -n "Recon "
FILESFTPOpen="$FOLDER/FTP-Open"
if [ ! -f "$FILESFTPOpen.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 21 -T4 --open -oN "$FILESFTPOpen.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESFTPOpen.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESFTPOpen-hosts.txt"
fi
echo " ✓"

##Probar FTP anonymous o vuln versión
echo -n "FTP anonymous "
FILESFTPanonymous="$FOLDER/FTP-anonymous"
if [ ! -f "$FILESFTPanonymous.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -sC -p 21 -T4 --script ftp-anon --open -oN "$FILESFTPanonymous.txt" -iL "$FILESFTPOpen-hosts.txt"
	grep "Anonymous" -B 5 "$FILESFTPanonymous.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESFTPanonymous-hosts.txt"
fi
echo " ✓"

##Download all anonyous FTP info
if $HEAVY; then
    echo -n "Download all anonymous FTP files "
	mkdir ftp
	cd ftp
	for IP in $(cat ../$FILESFTPOpen-hosts.txt); do
		echo $IP
		wget -m ftp://anonymous:anonymous@$IP -q
	done
	cd ..
    echo " ✓"
fi

################################ tftp ################################
echo "#### TFPT ####"
## Reconocimiento
echo -n "Recon "
FILEStFTPOpen="$FOLDER/tFTP-Open-Enum"
if [ ! -f "$FILESAUXREPLACE.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 69 -T4 --open --script 'tftp-enum' -oN "$FILESAUXREPLACE.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESAUXREPLACE.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESAUXREPLACE-hosts.txt"
fi
echo " ✓"

################################ nfs ################################
echo "#### NFS ####"
## Reconocimiento y scripts
echo -n "Recon "
FILESNFSOpen="$FOLDER/NFS-Open-Enum"
if [ ! -f "$FILESNFSOpen.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -p 111,2049 -T4 --open --script 'nfs-*' -oN "$FILESNFSOpen.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESNFSOpen.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESNFSOpen-hosts.txt"
fi
echo " ✓"

################################ Telnet ################################
echo "#### Telnet ####"
## Reconocimiento
echo -n "Recon "
FILESTelnet="$FOLDER/Telnet-Open"
if [ ! -f "$FILESTelnet.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 23 -T4 --open -oN "$FFILESTelnet.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FFILESTelnet.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FFILESTelnet-hosts.txt"
fi
echo " ✓"

################################ SSH ################################
echo "#### SSH ####"
## Reconocimiento
echo -n "Recon "
FILESSSH="$FOLDER/SSH-Open"
if [ ! -f "$FILESSSH.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 22 -T4 --open -oN "$FILESSSH.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESSSH.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESSSH-hosts.txt"
fi
echo " ✓"

echo -n "libsshscan "
## The vulnerability is present on versions of libssh 0.6+ and was remediated by a patch present in libssh 0.7.6 and 0.8.4.
## exploit: https://gist.githubusercontent.com/mgeeky/a7271536b1d815acfb8060fd8b65bd5d/raw/d4425b8504d25cf364185257eff04c6a8cc9a06e/cve-2018-10993.py
if [ ! -d "/opt/libssh-scanner" ]; then
	git clone https://github.com/leapsecurity/libssh-scanner.git /opt/libssh-scanner
	pip install -r /opt/libssh-scanner/requirements.txt
fi
for IP in $(cat "$FILESSSH-hosts.txt"); do
    python2.7 /opt/libssh-scanner/libsshscan.py -a -p 22 $IP 2> /dev/null | tee -a $FOLDER/SSH-libssh-scanner.txt
done

if ! grep -q 'is likely VULNERABLE to authentication bypass' $FOLDER/SSH-libssh-scanner.txt ; then
	mv $FOLDER/SSH-libssh-scanner.txt "$FOLDER/empty/"
fi

echo " ✓"

################################ SNMP ################################
echo "#### SNMP ####"
## Reconocimiento
echo -n "Recon "
FILESSNMP="$FOLDER/SNMP-Open"
if [ ! -f "$FILESSNMP.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose sudo nmap -v -Pn -n --disable-arp -sUV -p 161 -T4 --open -oN "$FILESSNMP.txt" -iL $TARGETFILE
	if ! grep "161/udp " "$FILESSNMP.txt" | grep -v -q 'udp open|filtered' ; then # If only open|filtered move to empty
		mv "$FILESSNMP.txt" "$FOLDER/empty/"
	fi

	grep 'Nmap scan report for ' "$FILESSNMP.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESSNMP-hosts.txt" 2> /dev/null
fi
echo " ✓"

##Scripts enumeración
echo -n "Enumeration "
FILESSNMPEnumeration="$FOLDER/SNMP-Enumeration"
if [ ! -f "$FILESSNMPEnumeration.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose sudo nmap -v -Pn -n --disable-arp -sUV -p 161 -T4 --open -sC -oN "$FILESSNMPEnumeration.txt" -iL "$FILESSNMP-hosts.txt"
	# TODO grep 'Nmap scan report for ' "$FILESSNMPEnumeration.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESSNMPEnumeration-hosts.txt"
fi

echo " ✓"

##Script brute force community
echo -n "Brute force community "
FILESSNMPBruteForce="$FOLDER/SNMP-Brute-Force-Community"
if [ ! -f "$FILESSNMPBruteForce.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose sudo nmap -v -Pn -n --disable-arp -sUV -p 161 -T4 --open --script snmp-brute -oN "$FILESSNMPBruteForce.txt" -iL "$FILESSNMP-hosts.txt"
	# TODO grep 'Nmap scan report for ' "$FILESSNMPBruteForce.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESSNMPBruteForce-hosts.txt"
fi
echo " ✓"

##All scripts
echo -n "All scripts "
FILESSNMPvuln="$FOLDER/SNMP-vuln"
if [ ! -f "$FILESSNMPvuln.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose sudo nmap -v -Pn -n --disable-arp -sUV -p 161 -T4 --open --script 'snmp-*' -oN "$FILESSNMPvuln.txt" -iL "$FILESSNMP-hosts.txt"
	grep 'Nmap scan report for ' "$FILESSNMPvuln.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESSNMPvuln-hosts.txt"
fi
echo " ✓"

################################ Kerberos ################################
echo "#### Kerberos ####"
## Reconocimiento
echo -n "Recon UDP & TCP "
FILESKerberosTCP="$FOLDER/KerberosTCP-Open"
if [ ! -f "$FILESKerberosTCP.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 88 -T4 --open -oN "$FILESKerberosTCP.txt" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESKerberosTCP.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESKerberosTCP-hosts.txt"
fi

FILESKerberosUDP="$FOLDER/KerberosUDP-Open"
if [ ! -f "$FILESKerberosUDP.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose sudo nmap -v -Pn -n --disable-arp -sUV -p 88 -T4 --open -oN "$FILESKerberosUDP.txt" -oG "$FILESKerberosUDP.grep" -iL $TARGETFILE
	if ! grep "88/open" "$FILESKerberosUDP.grep" | grep -v -q 'open|filtered/udp' ; then # If only open|filtered move to empty
		mv "$FILESKerberosUDP.grep" "$FILESKerberosUDP.txt"   "$FOLDER/empty/"
	fi
	grep 'open/udp' "$FILESKerberosUDP.grep" 2> /dev/null | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESKerberosUDP-hosts.txt" 2> /dev/null
	rm "$FILESKerberosUDP.grep" 2> /dev/null

fi


cat "$FILESKerberosTCP-hosts.txt" "$FILESKerberosUDP-hosts.txt" | sort -u > "$FOLDER/Kerberos-Open-hosts.txt"
echo " ✓"

## Enumeración usuarios
echo -n "User enumeration "
FILESKerberosTCPEnumeracionUsuarios="$FOLDER/KerberosTCP-Enumeracion-Usuarios"
if [ ! -f "$FILESKerberosTCPEnumeracionUsuarios.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -p 88 -T4 --open --script krb5-enum-users -oN "$FILESKerberosTCPEnumeracionUsuarios.txt"  -iL "$FILESKerberosTCP-hosts.txt"
fi

FILESKerberosUDPEnumeracionUsuarios="$FOLDER/KerberosUDP-Enumeracion-Usuarios"
if [ ! -f "$FILESKerberosUDPEnumeracionUsuarios.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose sudo nmap -v -Pn -n --disable-arp -sUV -p 88 -T4 --open --script krb5-enum-users -oN "$FILESKerberosUDPEnumeracionUsuarios.txt" -iL "$FILESKerberosUDP-hosts.txt"
fi
echo " ✓"

##Servicios de descubrimiento  de procolos como LLMNR, NBT-NS o MDNS
#responder -I $INTERFACE -wrfd

################################ Servidores de aplicaciones (8000-10000) ################################
echo "#### Servidores de aplicaciones (8000-10000) ####"
# Apache Tomcat, phpmyadmin, jenkins, jboss, apache struts

## Reconocimiento
echo -n "Recon "
#masscan $TARGET -p 8000-10000 | awk 'NF{print $NF}' > "$FOLDER/server-ap-open.txt"
FILESserverAPPopen="$FOLDER/server-app-open"
if [ ! -f "$FILESserverAPPopen.txt" ] || [ $FORCE  = true ]; then
	printIfVerbose nmap -v -Pn -n --disable-arp -sV -sC -p 8000-10000 -T4 --open --script 'discovery,safe,version,vuln' -oN "$FILESserverAPPopen.txt" -oX "$FILESserverAPPopen.xml" -iL $TARGETFILE
	grep 'Nmap scan report for ' "$FILESserverAPPopen.txt" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > "$FILESserverAPPopen-hosts.txt"
fi
echo " ✓"

## CAPTURES
echo -n "Aquatone Screenshot "
mkdir "$FOLDER/aquatoneAPPs/"
cat "$FILESserverAPPopen.xml" | /opt/aquatone/aquatone -nmap -out "$FOLDER/aquatoneAPPs/"
echo " ✓"

echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Para cerrar todos los procesos en background usar kill % ${endColour}\n"


################################ WEB HEAVY ################################

if $HEAVY; then
	if command -v seclists &>/dev/null; then
		sudo apt install seclists prips -y
	fi

	for IP in `cat "$FILESWEBenum-hosts.txt"`; do # For each IP or domain
		echo $IP
		printIfVerbose wfuzz -c -w /usr/share/seclists/Discovery/Web-Content/common.txt -f wfuzz-common.txt -L --hc 404 http://$IP/FUZZ -f $FOLDER/WEB-wfuzz-common.txt
		printIfVerbose wfuzz -c -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -f wfuzz-directory-list.txt -L --hc 404 http://$IP/FUZZ $FOLDER/WEB-wfuzz-medium.txt
		printIfVerbose wfuzz -c -w /usr/share/seclists/Discovery/Web-Content/CGIs.txt -f wfuzz-cgis.txt -L --hc 404 http://$IP/FUZZ $FOLDER/WEB-wfuzz-CGIs.txt
		printIfVerbose dirsearch -F -b --random-agent --url http://$IP -e txt,php,xml,conf.zip,gz,tar.gz,sql --timeout=40 --max-rate=5 -o $FOLDER/WEB-dirsearch.txt
		#ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt:FUZZ -u https://FUZZ.<domain.com>/

		printIfVerbose nikto -host=http://$IP -maxtime=30m -o  $FOLDER/WEB-nikto.txt
		printIfVerbose whatweb http://$IP --log-verbose=$FOLDER/WEB-whatweb.txt
		printIfVerbose whatweb http://$IP -v --follow-redirect=always --open-timeout 120 --read-timeout 120 --max-redirects=30 --aggression=3 --log-verbose=$FOLDER/WEB-whatweb-aggresion.txt
	done
fi

# mv empty to folder empty
find . -type f -empty -print -exec mv {} "$FOLDER/empty/" \;

# mv empty nmap -v files
NMAP=`grep '# nmap -v done' $FOLDER/*.txt  -l` #All nmap -v files
for F in `echo "$NMAP"`; do       
	if ! grep -q "nmap -v scan report" $F -l ; then #empty file
		 mv $F "$FOLDER/empty/"
	fi
done
