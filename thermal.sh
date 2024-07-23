#!/bin/bash
# config parameters
Tjoffset=25 # offset from Tjmax (100 C) therefore 25 = max 75 C
fan_speeds=(50 0x00 0x00 55 0x10 0x10 60 0x20 0x20 65 0x40 0x40 70 0xff 0xff 100 0xff 0xff) # Temperature, boost below fan 1, boost below fan 2
processor_thermaldevice_location="/sys/bus/pci/devices/0000:00:04.0/tcc_offset_degree_celsius" # location of tcc_offset file 
# CONSTANTS - DO NOT CHANGE !
get_laptop_model=(0x1a 0x02 0x02)
get_power_mode=(0x14 0x0b 0x00)
set_power_mode=(0x15 0x01)    #To be used with a parameter
toggle_G_mode=(0x25 0x01)
get_G_mode=(0x25 0x02)
set_fan1_boost=(0x15 0x02 0x32) #To be used with a parameter
get_fan1_boost=(0x14 0x0c 0x32)
get_fan1_rpm=(0x14 0x05 0x32)
get_cpu_temp=(0x14 0x04 0x01)
set_fan2_boost=(0x15 0x02 0x33) #To be used with a parameter
get_fan2_boost=(0x14 0x0c 0x33)
get_fan2_rpm=(0x14 0x05 0x33)
get_gpu_temp=(0x14 0x04 0x06)
# END OF CONSTANTS 

# setup
sudo modprobe acpi_call
sudo modprobe processor_thermal_device_pci

function acpi_call {
    # $1 $2 $3 $4 - arguments to ACPI call.
    echo "\_SB.AMWW.WMAX 0 ${1-0x00} {${2-0x00}, ${3-0x00}, ${4-0x00}, 0x00}" | sudo tee /proc/acpi/call > /dev/null; echo $(($(sudo cat /proc/acpi/call | tr -d '\0'))) # send acpi call and do black magic fuckery on the return value
}
# main loop
while true;
do
    cpu_temp=$(acpi_call ${get_cpu_temp[@]}) # get temps
    gpu_temp=$(acpi_call ${get_gpu_temp[@]})
    echo "CPU TEMP: $cpu_temp C"
    echo "GPU TEMP: $gpu_temp C"
    echo "FAN 1 BOOST: $(acpi_call ${get_fan1_boost[@]})"
    echo "FAN 2 BOOST: $(acpi_call ${get_fan2_boost[@]})"
    if [ $cpu_temp -ge $gpu_temp ];  # which is the biggest temp ?
    then
        biggest_temp=$cpu_temp
    else
        biggest_temp=$gpu_temp
    fi
    #echo $biggest_temp #debug
    speedindex=0
    while [ $biggest_temp -ge ${fan_speeds[speedindex]} ]
    do
        speedindex=$(($speedindex+3))
    done
    #echo $speedindex   #debug
    fan1_boost=${fan_speeds[speedindex+1]}
    fan2_boost=${fan_speeds[speedindex+2]}
    acpi_call ${set_fan1_boost[@]} $fan1_boost > /dev/null # set fan speeds
    acpi_call ${set_fan2_boost[@]} $fan2_boost > /dev/null # 
        
    echo "Tjoffset $(echo $Tjoffset | sudo tee $processor_thermaldevice_location) C" # set and print Tjoffset
    sleep 2
done
