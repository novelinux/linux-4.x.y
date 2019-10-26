# __lock_page_killable

```
int __lock_page_killable(struct page *page)
{
	DEFINE_WAIT_BIT(wait, &page->flags, PG_locked);

	return __wait_on_bit_lock(page_waitqueue(page), &wait,
					bit_wait_io, TASK_KILLABLE);
}
EXPORT_SYMBOL_GPL(__lock_page_killable);
```

当数据还未就绪时,调用__wait_on_bit_lock()等待解除PG_locked和设置PG_update。

当数据读到内存中后,磁盘控制器就会向CPU发一个中断,然后就会执行中断处理程序。为了简化我们的分析,下图给出了读数据完成后,中断处理的函数栈。

```
#############Wake up task name:md5sum, pid:3832, in_iowait:1, state:130, flags:402000 ###########
Pid: 0, comm: swapper Tainted: G
--------------- HT 2.6.32279.debug #43
Call Trace:
<IRQ> [<ffffffff81060167>] ? try_to_wake_up+0x2f7/0x480
[<ffffffff810137f3>] ? native_sched_clock+0x13/0x80
[<ffffffff81060302>] ? default_wake_function+0x12/0x20
[<ffffffff81092186>] ? autoremove_wake_function+0x16/0x40
[<ffffffff810921eb>] ? wake_bit_function+0x3b/0x50
[<ffffffff8104e309>] ? __wake_up_common+0x59/0x90
[<ffffffff810533e8>] ? __wake_up+0x48/0x70
[<ffffffff81092121>] ? __wake_up_bit+0x31/0x40
[<ffffffff81114277>] ? unlock_page+0x27/0x30
[<ffffffff811b6dc9>] ? mpage_end_io+0x39/0x90
[<ffffffff811b138d>] ? bio_endio+0x1d/0x40
[<ffffffff81254d7b>] ? req_bio_endio+0x9b/0xe0
[<ffffffff81256917>] ? blk_update_request+0x107/0x490
[<ffffffff81256cc7>] ? blk_update_bidi_request+0x27/0xa0
[<ffffffff8125814f>] ? blk_end_bidi_request+0x2f/0x80
[<ffffffff812581f0>] ? blk_end_request+0x10/0x20
[<ffffffff8136c22f>] ? scsi_io_completion+0xaf/0x6c0
[<ffffffff81363332>] ? scsi_finish_command+0xc2/0x130
[<ffffffff8136c9a5>] ? scsi_softirq_done+0x145/0x170
[<ffffffff8125d825>] ? blk_done_softirq+0x85/0xa0
[<ffffffff81073f61>] ? __do_softirq+0xc1/0x1e0
[<ffffffff810db936>] ? handle_IRQ_event+0xf6/0x170
[<ffffffff8100c24c>] ? call_softirq+0x1c/0x30
[<ffffffff8100de85>] ? do_softirq+0x65/0xa0
[<ffffffff81073d45>] ? irq_exit+0x85/0x90
[<ffffffff81505d15>] ? do_IRQ+0x75/0xf0
[<ffffffff8100ba53>] ? ret_from_intr+0x0/0x11
<EOI> [<ffffffff812f7a0a>] ? acpi_idle_enter_c1+0xa3/0xc1
[<ffffffff812f79e9>] ? acpi_idle_enter_c1+0x82/0xc1
[<ffffffff81407847>] ? cpuidle_idle_call+0xa7/0x140
[<ffffffff81009e06>] ? cpu_idle+0xb6/0x110
[<ffffffff814f6eff>] ? start_secondary+0x22a/0x26d
```

[mpage_end_io](./../../fs/ext4/readpage.c/mpage_end_io.md)