#!/bin/sh
## ASSUMES CGROUPSv2

# Store current cgroup
shell_pid=$$
stored_cgroup="$(cut -d":" -f3 "/proc/$shell_pid/cgroup")"
switched_cgroup=false

# if we are not already inside / cgroup, switch us
if ! grep "\b$shell_pid\b" "/sys/fs/cgroup/cgroup.procs" > /dev/null; then
        printf "[I] Switching shell from %s cgroup to root cgroup\n" "$stored_cgroup"
        echo "$shell_pid" > "/sys/fs/cgroup/cgroup.procs"
        switched_cgroup=true
else
        printf "[I] Already in root cgroup\n"
fi

cgroup_name="cg_test"
cgroup_dir="/sys/fs/cgroup/$cgroup_name"

byte_memory_input=6442450944 # 6 GB
byte_memory_limit=2147483648 # 2 GB

if [ ! -d $cgroup_dir ]; then
        mkdir $cgroup_dir
else
        printf "[I] %s already exist\n" "$cgroup_dir"
fi

# Specify we want memory
if [ $(grep -i "memory" "$cgroup_dir/../cgroup.controllers" | wc -l) -eq 1 ]; then
        if [ ! $(grep -i "memory" "$cgroup_dir/../cgroup.subtree_control" | wc -l) -eq 1 ]; then
                printf "[E] Missing memory in subtree parent control cgroup\n"
                exit 1
        fi
        printf "[I] Memory is available on parent cgroups, we can add limit on our cgroup\n"
else
        printf "[E] Memory unavailable on cgroups, check parent available resources in $cgroup_dir, exiting..\n"
        exit 1
fi
## BE CAREFUL TO NOT ADD ANYTHING INTO OUR NEWLY CREATED CGROUP SUBTREE_CONTROL
## See https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html#no-internal-process-constraint
## It makes it impossible to add any process to our cgroup, since It stops being a leaf

# Add our memory limit to the cgroup
# memory.high is the memory usage throttle limit
# memory.max is the memory usage hard limit, going beyond invokes OOM grimreaper
if [ -f "$cgroup_dir/memory.high" ]; then
        printf "[I] Adding memory limit of %s to our cgroup\n" "$byte_memory_limit"
        echo "$byte_memory_limit" >> "$cgroup_dir/memory.max"
else
        printf "[E] Missing %s\n" "$cgroup_dir/memory.max"
        printf "[E] Unable to add memory limit, exiting..\n"
        exit 1
fi

# Now that our cgroup is created with a memory limit
# We need to execute our program in its namespace and add its PID to our cgroups
</dev/zero head -c $byte_memory_input | tail &

process_pid=$!

printf "[I] Created memory command at %s\n" "$process_pid"
printf "[I] Currently executing in cgroup %s\n" "$(cut -d":" -f3 "/proc/$process_pid/cgroup")"
printf "[I] Adding PID %s to %s/cgroup.procs\n" "$process_pid" "$cgroup_dir"
printf "[I] Switching process to our new cgroup %s\n" "$cgroup_name"
echo "$process_pid" >> "$cgroup_dir/cgroup.procs"

#
# Sleep for a bit, not necessary but better to read what's going on
printf "[I] Going to sleep while you read this\n"
sleep 15
printf "[I] Killing memory process as test is over\n"
kill -9 "$process_pid"
printf "[I] Kill successfull, exiting soon\n"

if [ "$switched_cgroup" = true ]; then
        printf "[I] Switching back to original cgroup %s\n" 
        echo "$shell_pid" > "/sys/fs/cgroup$stored_cgroup/cgroup.procs"
        printf "[I] Now running shell in cgroup: %s\n" "$(cut -d":" -f3 "/proc/$shell_pid/cgroup")"
else
        printf "[I] We were already in root cgroup, just exiting without switching\n"
fi

exit 0
