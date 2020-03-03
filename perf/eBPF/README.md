# eBPF running on Android

## Kernel Config

```
CONFIG_BPF=y
CONFIG_BPF_JIT=y
CONFIG_HAVE_BPF_JIT=y
CONFIG_BPF_EVENTS=y
CONFIG_KPROBES=y
CONFIG_KPROBE_EVENT=y
CONFIG_UPROBES=y
CONFIG_UPROBE_EVENT=y
CONFIG_DEBUG_PREEMPT=y
CONFIG_PREEMPTIRQ_EVENTS=y
CONFIG_FTRACE_SYSCALLS=y
```

Running following commands:

```
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-androidkernel-
make boardname_defconfig
```

## adeb

```
git clone git@github.com:leeminghao/adeb.git ~/bin/
export PATH=$HOME/bin/adeb:$PATH
export ADEB_REPO_URL="github.com/joelagnel/adeb/"
adeb prepare --full --kernelsrc /path/to/kernel-source
adeb shell
```

## examples

```
root@localhost:/usr/share/bcc/tools# fileslower
Tracing sync read/writes slower than 10 ms
TIME(s)  COMM           TID    D BYTES   LAT(ms) FILENAME
8.993    ndroid.systemu 2362   R 32       103.51 com.xiaomi.aiasst.service.png
19.923   mistat_db      3940   W 4096      23.71 mistat_ev-journal
40.842   com.miui.home  3119   W 37        11.27 MiuiHome.apk
40.947   .miui.miservic 7836   W 8192      13.03 dipper.xml
40.984   system_server  1538   R 25        39.59 XMRemoteController.apk
```

## Android bpf

```
aarch64-linux-android29-clang --target=bpf -c  -nostdlibinc -I system/bpf/progs/include/ -isystem bionic/libc/include -isystem bionic/libc/kernel/uapi -isystem bionic/libc/kernel/uapi/asm-arm64 -isystem bionic/libc/kernel/android/uapi -O2 system/bpfprogs/test/bpf_load_tp_prog.c
```

## References

* https://www.ibm.com/developerworks/cn/linux/l-lo-eBPF-history/index.html
* https://gist.github.com/dalehamel/43a6d96c63ef4adfd648c0862eb5a727