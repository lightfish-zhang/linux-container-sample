#!/bin/sh

# set env
net_nums="0 1 2"
ip_prefix="10.0.1"
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/conf/default/accept_local
echo 0 > /proc/sys/net/ipv4/conf/default/rp_filter

# setup bridge br0
ip link add br0 type bridge
ip addr add $ip_prefix.0 dev br0
ip link set dev br0 up

## show br0 info
echo br0 ip:
ip addr show dev br0|grep -w inet
echo

# setup namespace
for i in $net_nums
do
ip netns add net$i
ip netns exec net$i ip link set dev lo up
ip link add veth$i type veth peer name veth_$i
ip link set veth_$i netns net$i
ip netns exec net$i ip link set dev veth_$i name ech0
ip netns exec net$i ip addr add $ip_prefix.$((i+1))/24 dev ech0
ip netns exec net$i ip link set dev ech0 up
ip link set dev veth$i master br0
ip link set dev veth$i up

## show namespace info
echo net$i ip route:
ip netns exec net$i ip route
echo
done

# show info
# bridge link

# test ping
for i in $net_nums
do
for j in $net_nums
do
echo net$i ping to net$j 
ip netns exec net$i ping $ip_prefix.$((j+1)) -c 1 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"FAIL") }'
echo
done
done


# clean
for i in $net_nums
do
ip netns delete net$i
done
ip link del br0
