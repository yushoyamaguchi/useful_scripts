#/bin/bash

#ip link show | grep br- | cut -d " " -f 2 | cut -d ":" -f 1 > nic_list.txt

for line in `ip link show | grep br- | cut -d " " -f 2 | cut -d ":" -f 1`
do
  ip link del $line
done

