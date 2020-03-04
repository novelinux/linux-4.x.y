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

### objdump

```
$ llvm-objdump -d out/target/product/dipper/system/etc/bpf/bpf_load_tp_prog.o

out/target/product/dipper/system/etc/bpf/bpf_load_tp_prog.o:	file format ELF64-BPF

Disassembly of section tracepoint/sched/sched_switch:
tp_sched_switch:
       0:	bf 16 00 00 00 00 00 00 	r6 = r1
       1:	85 00 00 00 08 00 00 00 	call 8
       2:	63 0a fc ff 00 00 00 00 	*(u32 *)(r10 - 4) = r0
       3:	61 61 38 00 00 00 00 00 	r1 = *(u32 *)(r6 + 56)
       4:	63 1a f8 ff 00 00 00 00 	*(u32 *)(r10 - 8) = r1
       5:	bf a2 00 00 00 00 00 00 	r2 = r10
       6:	07 02 00 00 fc ff ff ff 	r2 += -4
       7:	bf a3 00 00 00 00 00 00 	r3 = r10
       8:	07 03 00 00 f8 ff ff ff 	r3 += -8
       9:	18 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 	r1 = 0 ll
      11:	b7 04 00 00 00 00 00 00 	r4 = 0
      12:	85 00 00 00 02 00 00 00 	call 2
      13:	b7 00 00 00 00 00 00 00 	r0 = 0
      14:	95 00 00 00 00 00 00 00 	exit
```

## References

* https://www.ibm.com/developerworks/cn/linux/l-lo-eBPF-history/index.html
* https://gist.github.com/dalehamel/43a6d96c63ef4adfd648c0862eb5a727