#/bin/bash

#ip link show | grep br- | cut -d " " -f 2 | cut -d ":" -f 1

ip link show | grep br- | cut -d " " -f 2 | cut -d ":" -f 1 > nic_list.txt

while read line
do
  ip link del $line
done < ./nic_list.txt

rm nic_list.txt

