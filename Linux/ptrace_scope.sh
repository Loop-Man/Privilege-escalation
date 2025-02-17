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

# Lo primero será crear la función ctrl_c() para crear una salida controlada del script
function ctrl_c(){
    # El -e para que no introduzca el echo el new line y tengamos que ponerlo nosotros manualmente (\n)
    echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Saliendo de manera controlada ${endColour}\n"
    exit 0
}

# Lo segundo será comprobar si ptrace_scope tiene el valor cero y si gdb está instalado, requesitos necesarios para que este exploit funcione

echo -ne "\n${yellowColour}[i]${endColour}${grayColour} Chequeando que el valor de 'ptrace_scope' esté a 0 ${endColour}"

    #Con el -q en el grep hago que no saque nada por pantalla de la busqueda del valor en este caso cero y en caso de encontrarlo que salga con código de estado 0 (correcto)
    #Podemos ver el codigo de estado del ultimo comando con echo $?

if grep -q "0" < /proc/sys/kernel/yama/ptrace_scope; then
    echo -e "${greenColour}\t[V]${endColour}"
    
else 
    echo -e "${redColour}\t[X]${endColour}"
    echo -e "${yellowColour}[*]${endColour}${grayColour} El sistema no es vulnerable, try harder !!! ${endColour}"
fi
