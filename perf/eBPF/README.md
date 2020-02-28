# eBPF

### Android bpf

```
aarch64-linux-android29-clang --target=bpf -c  -nostdlibinc -I system/bpf/progs/include/ -isystem bionic/libc/include -isystem bionic/libc/kernel/uapi -isystem bionic/libc/kernel/uapi/asm-arm64 -isystem bionic/libc/kernel/android/uapi -O2 system/bpfprogs/test/bpf_load_tp_prog.c
```

## References

* https://www.ibm.com/developerworks/cn/linux/l-lo-eBPF-history/index.html
