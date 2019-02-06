#!/bin/sh

# 挂载一颗不和任何subsystem绑定的cgroup树
mkdir my_cgroup
#由于name=demo的cgroup树不存在，所以系统会创建一颗新的cgroup树，然后挂载到demo目录
mount -t cgroup -o none,name=my_cgroup my_cgroup ./my_cgroup

mkdir test
cd test

pid=`ps ax|grep -v grep|grep -w linux-container.out|awk '{print $1}'`

# 限制 cpu 资源
mkdir cpu
sh -c "echo ${pid} > cpu/cgroup.procs"
# 限制只能使用1个CPU（每250ms能使用250ms的CPU时间）
echo 250000 > cpu/cpu.cfs_quota_us
echo 250000 > cpu/cpu.cfs_period_us


# 限制 memory 资源
mkdir memory
sh -c "echo ${pid} > memory/cgroup.procs"
sh -c "echo 10M > memory/memory.limit_in_bytes"


# clean
rmdir cpu
rmdir memory
cd ../
# 移动 pid 到父目录，才可以删除 test 目录
sh -c "echo ${pid} > cgroup.procs"
rmdir test
# Linux重启后，挂载点会消失