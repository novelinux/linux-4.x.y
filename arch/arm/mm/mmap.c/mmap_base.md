mmap_base
========================================

可以根据栈的最大长度，来计算栈最低的可能位置，用作mmap区域的起始点，但内核
会确保栈至少跨越128MB的空间。另外，如果指定的栈界限非常巨大，那么内核会至少
保证有一小部分地址空间不被占据。如果要求使用地址空间随机化机制，上述位置会
减去一个随机的偏移量值，最大为1MB.另外，内核会确保该区域会对齐到页帧，
这是体系结构的要求.

path: arch/arm/mm/mmap.c
```
/* gap between mmap and stack */
#define MIN_GAP (128*1024*1024UL)
#define MAX_GAP ((TASK_SIZE)/6*5)

...

static unsigned long mmap_base(unsigned long rnd)
{
    unsigned long gap = rlimit(RLIMIT_STACK);

    if (gap < MIN_GAP)
        gap = MIN_GAP;
    else if (gap > MAX_GAP)
        gap = MAX_GAP;

    return PAGE_ALIGN(TASK_SIZE - gap - rnd);
}
```