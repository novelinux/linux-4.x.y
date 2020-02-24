## Perf analysis

### The common tools to run are:

```
1.uptime
2.dmesg | tail
3.vmstat 1
4.mpstat -P ALL 1
5.pidstat 1
6.iostat -xz 1
7.free -m
8.sar -n DEV 1
9.sar -n TCP,
10.top
```

### BCC TOOL CHECKLIST

```
1. execsnoop
2. opensnoop
3. ext4slower (or btrfs*, xfs*, zfs*)
4. biolatency
5. biosnoop6. cachestat
7. tcpconnect
8. tcpaccept
9. tcpretrans
10. runqlat
11. profile
```