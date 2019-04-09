## hs error analysis

### Thread Stack

```
---------------  T H R E A D  ---------------

Current thread (0x00007fdaec018800):  JavaThread "Unknown thread" [_thread_in_vm, id=155455, stack(0x00007fdaf2d37000,0x00007fdaf2db8000)]

Stack: [0x00007fdaf2d37000,0x00007fdaf2db8000],  sp=0x00007fdaf2db5e10,  free space=507k
Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
V  [libjvm.so+0xac826a]  VMError::report_and_die()+0x2ba
V  [libjvm.so+0x4fd4cb]  report_vm_out_of_memory(char const*, int, unsigned long, VMErrorType, char const*)+0x8b
V  [libjvm.so+0x924f53]  os::Linux::commit_memory_impl(char*, unsigned long, bool)+0x103
V  [libjvm.so+0x9253f5]  os::pd_commit_memory_or_exit(char*, unsigned long, unsigned long, bool, char const*)+0x35
V  [libjvm.so+0x91f3e6]  os::commit_memory_or_exit(char*, unsigned long, unsigned long, bool, char const*)+0x26
V  [libjvm.so+0x5c466f]  G1PageBasedVirtualSpace::commit_internal(unsigned long, unsigned long)+0xbf
V  [libjvm.so+0x5c48fc]  G1PageBasedVirtualSpace::commit(unsigned long, unsigned long)+0x11c
V  [libjvm.so+0x5c75e0]  G1RegionsLargerThanCommitSizeMapper::commit_regions(unsigned int, unsigned long)+0x40
V  [libjvm.so+0x62ac57]  HeapRegionManager::commit_regions(unsigned int, unsigned long)+0x77
V  [libjvm.so+0x62bef1]  HeapRegionManager::make_regions_available(unsigned int, unsigned int)+0x31
V  [libjvm.so+0x62c470]  HeapRegionManager::expand_by(unsigned int)+0xb0
V  [libjvm.so+0x59b7f9]  G1CollectedHeap::expand(unsigned long)+0x199
V  [libjvm.so+0x5a1af5]  G1CollectedHeap::initialize()+0x895
V  [libjvm.so+0xa902e3]  Universe::initialize_heap()+0xf3
V  [libjvm.so+0xa9084e]  universe_init()+0x3e
V  [libjvm.so+0x63e3e5]  init_globals()+0x65
V  [libjvm.so+0xa73f3e]  Threads::create_vm(JavaVMInitArgs*, bool*)+0x23e
V  [libjvm.so+0x6d2ce4]  JNI_CreateJavaVM+0x74
C  [libjli.so+0x745e]  JavaMain+0x9e
C  [libpthread.so.0+0x7dc5]  start_thread+0xc5
```

###