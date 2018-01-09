# Impact of ext4’s discard option on my SSD

Solid-state drives (SSDs) are seen as the future of mass storage by many. They are famous for their high performance: extremely low seek times, since there is no head that needs move to a position and then wait for the spinning disk to come around to where it needs to read/write; but also higher throughput of sequential data: My 2,5″ OCZ Vertex LE (100 GB) is rated at 235 MB/s sustained write speed, and read speeds up to 270 MB/s, for example.

There is a caveat though – quoting Wikipedia:

In SSDs, a write operation can be done on the page-level, but due to hardware limitations, erase commands always affect entire blocks. As a result, writing data to SSD media is very fast as long as empty pages can be used, but slows down considerably once previously written pages need to be overwritten. Since an erase of the cells in the page is needed before it can be written again, but only entire blocks can be erased, an overwrite will initiate a read-erase-modify-write cycle: the contents of the entire block have to be stored in cache before it is effectively erased on the flash medium, then the overwritten page is modified in the cache so the cached block is up to date, and only then is the entire block (with updated page) written to the flash medium. This phenomenon is known as write amplification.

So, SSDs are fast at writing, but only when their free space is neatly trimmed. The only component in your software stack that knows which parts of your SSD should be trimmed, is your file system. That is why there is a file system option in ext4 (my current file system of choice), called “discard”. When this option is active, space that is freed up in the file system is reported to the SSD immediately, and then the SSD does the trimming right away. This will make the next write to that part of the SSD as fast as expected. Obviously, trimming takes time – but how much time exactly? I wanted to find out, and did the following: I measured the time to unpack and then delete the kernel sources (36706 files amounting to 493 MB, which is what I call a big bunch of small files). I did it three times with and three times without the “discard” option, and then took the average of those three tries:

Without “discard” option:

Unpack: 1.21s
Sync: 1.66s (= 172 MB/s)
Delete: 0.47s
Sync: 0.17s
With “discard” option:

Unpack: 1.18s
Sync: 1.62s (= 176 MB/s)
Delete: 0.48s
Sync: 40.41s
So, with “discard” on, deleting a big bunch of small files is 64 times slower on my SSD. For those ~40 seconds any I/O is really slow, so that’s pretty much the time when you get a fresh cup of coffee, or waste time watching the mass storage activity LED.

Conclusion
Don’t enable the “discard” option if you have a similar SSD. A much better way to keep your free space neatly trimmed for good write speeds is, to trigger a complete walk over the file system’s free space, and tell the SSD to trim that all at once. And of course you would do that at times when you don’t actually want to use the system (e.g. in a nightly cron job, or with a script that gets launched during system shutdown). This can be done with the ‘fstrim’ command (that comes with util-linux), which takes around six minutes for my currently 60% filled 95 GB file system.

Update (2011-07-08): I forgot some details that may be interesting:

Kernel version: 2.6.39.2
SSD firmware version: 1.32
CPU: AMD Phenom II X4 965
44 Responses to “Impact of ext4’s discard option on my SSD”
matt
July 9, 2011 at 3:21 CST
I’m trying to understand this completely. I somewhat recently setup an SSD under linux and ext4 as well. All the research I’ve done says by all means, set the discard option in your fstab.

From my understanding, without the discard option set on mount, your SSD will ignore ANY trim command. So your fstrim cron is essentially acting like it’s working with a spindle disk rather than SSD.

Am I totally misunderstanding something here?

Reply
Patrick
July 9, 2011 at 5:01 CST
Hi matt,
I think there are basically three options

1) No “discard”, never run fstrim
2) With “discard”
3) No “discard”, run fstrim from time to time

Option 1 is the least desirable: That way, the SSD would degrade in write performance after some time considerably, because it would never get any TRIM commands from the kernel, so once it runs out of trimmed free space, it needs to do the whole read-erase-modify-write thing, everytime you write new data.
Option 2 will prevent that performance degradation, but it does it at a cost: Every delete operation you trigger on your file system will immediately cause the kernel to issue TRIM commands for the respective blocks, which, as I showed in my post, can be really slow.
Option 3, which is what I recommend for now*, will prevent performance degradation, too, but the TRIMming does not happen directly after you delete data from your file system, but at arbitrary later times.

*) I hope that the smart kernel guys can figure out a way to make “discard” work in a way that it does not have a negative impact on the user experienced performance in the future – e.g. by queueing the TRIM requests, and issuing them in slow progression, and only while there is zero other I/O going on, or something like that.

Reply
nite69
May 21, 2012 at 3:25 CST
Just a note; doesn’t the ‘sync’ command force all the “smart kernel guy developed” optimization for discard to be skipped? ie, if there is a queue for TRIM request, sync will force it to be skipped and TRIM will we excecuted immediately, which will force the systemto delay while TRIM is being excecuted?

“*) I hope that the smart kernel guys can figure out a way to make “discard” work in a way that it does not have a negative impact on the user experienced performance in the future – e.g. by queueing the TRIM requests, and issuing them in slow progression, and only while there is zero other I/O going on, or something like that.”

Reply
Patrick
May 21, 2012 at 9:29 CST
Hi,

yes, you might be right – I always thought of ‘sync’ as “flush out the write cache” – which doesn’t necessarily include “clean up” operations like TRIM/discard, but I just don’t know enough about how it works to be sure (and I don’t have the time to dig into it, either).

All I can say is that, at the time when I wrote this article, having ‘discard’ on and doing a delete operation did feel very similar to running ‘sync’ after a delete operation – maybe delayed by a few seconds, but the “system hang” was there, definitely no sign of useful queuing and waiting for user inactivity.

Smart kernel guys, please leave a comment if you have changed anything in that area! 😀

Reply
Matteo
May 9, 2013 at 20:16 CST
What you say doesn’t make any sense. By its very nature, sync means “apply all changes now”, so that the on-disk status is consistent with the in-kernel one.

If the kernel developers were to accept your proposal, sync would immediately change its meaning to “apply some changes now and defer some others, don’t bother if disk and kernel are not consistent”.

 Patrick
May 9, 2013 at 20:37 CST
Good point, as I said sometime earlier, I always thought of ‘sync’ as ‘flush / persist’, not including cleanup (like trim, defrag, etc. things). But the name ‘sync’ actually hints that it brings the kernel’s and the on-disk’s universes in sync.

 Michael Shigorin
May 30, 2012 at 14:32 CST
I see the “user experience” measured a bit phoronixishly: the (second) sync isn’t what one does routinely, and if one is issuing it and worrying for his SSD then one is responsible for thinking it over in the first place; the only valid reason for sync-after-rm on an SSD for me is trying to ensure that the information is rather destroyed, and then I’d rather be worrying about overwriting all of the free space a few times. As a general habit, sync(1) on every occasion is rather wrong for an SSD user (and for busy HDDs user as well, heh).

What could *probably* be done is the kernel code making sure that sync(2)/fsync(2) do ensure the data hitting the plates or flash to the best of kernel’s knowledge, waking up a trimming kernel thread for that device asynchronously, and returning without waiting for that (disclaimer: I’m no kernel developer).

The current sync behaviour with discard warrants that SSD is ready for the *next* write as well, and it’s easy to fool one’s self with the execution time of “no-discard” second sync since the slow process will just have to happen sometime. It’s a tradeoff: one can try and shift the slow part to the wee hours in the morning but then get hit by it happening across the heavy debugging session or temporarily exhausting the trimmed free space to hit RMW during sane hours as well.

So don’t hold your breath, no silver bullet discovered yet again. And make sure you have read fstrim’s author warnings as well, there were some.

Reply
Patrick
May 31, 2012 at 16:05 CST
Hehe, “phoronixishly” – I didn’t even know that adverb, yet 😉

As I pointed out in another comment: “All I can say is that, at the time when I wrote this article, having ‘discard’ on and doing a delete operation did feel very similar to running ‘sync’ after a delete operation – maybe delayed by a few seconds, but the “system hang” was there, definitely no sign of useful queuing and waiting for user inactivity.”
And without sync, I couldn’t have gotten that horrible lag counted by ‘time’. There is probably a more scientific way to do it less phoronixishly – feel free to repeat the experiment and link to it here 🙂

I’m completely aware that having ‘discard’ on, gives some more predictability – but at the price that it’s *always* slow and laggy when you write (after there is no more trimmed space) or delete data. It’s not even a trade-off, really, because with ‘discard’ on, it’s just always slow, and without ‘discard’ it just gets to that slowness after you used up all the trimmed space (which is when you should run fstrim again).

As for fstrim’s author warnings – do you have a pointer? I would have expected them in the man page, but couldn’t find any.

Reply
Ellis Percival
December 16, 2015 at 8:05 CST
In this precise instance, the user-experience impact is not necessarily improved by disabling ‘discard’, however once the trim queue is full (ie. by deleting more files), then the user is held until the SSD performs the TRIM operations complete (or until the queue size reduces).

As I write this, I am waiting for an SSD to do precisely this – it deletes a lot of files very quickly (filling up some kind of queue – presumably TRIM) and then freezes for minutes at a time on one file while it catches up.

Using ‘sync’ to demonstrate this phenomenon on less files is good enough in my opinion, but I’m sure you could perform a demonstration without it if you had enough files to delete (and perhaps ones which weren’t created contiguously).

Reply
Ellis Percival
December 16, 2015 at 8:08 CST
Sorry for the double-post, but this is what I’m currently deleting, which is taking 10+ minutes (the first tar.gz file, extracted, only about 1GB):
http://www.freedb.org/en/download__server_software.4.html

 vav
July 9, 2011 at 3:26 CST
Awesomely good timing. Been tweaking and testing different parameters on my new SSD. You saved me some puzzling and trials. For your referencing pleasure here’s the baselayout 2 shutdown fstrim script I’ve started using. (Wasn’t sure if fstrim would cross fs boundaries, but it doesn’t thankfully.)

#!/sbin/runscript

description=”Trims root SSD filesystem”

depend()
{
after killprocs
before mount-ro
}

start()
{
ebegin “Trimming (SSD) rootfs free space”
/sbin/fstrim /
eend $?
}

return 0

Reply
Patrick
July 9, 2011 at 5:09 CST
Hi,
great! And thanks for the init script 🙂

I’m thinking about tracking free space and the “total bytes written” SMART value of the SSD, and then let a script decide based on that information whether there is a need for an fstrim run, or not. But I haven’t gotten a clear picture on how to exactly do it, yet…

Reply
Patrick
July 9, 2011 at 13:14 CST
I came up with a script, but upon testing I found out that the “Lifetime Writes GiB” SMART value only increases in 64 GiB steps. That’s a show stopper – it causes the script to execute fstrim with a rather large delay (during which the SSD will perform poorly), if free space is less than 64 GiB.

So I guess I’ll just go on running fstrim once in a while manually.

Reply
Patrick
August 20, 2011 at 23:40 CST
After giving it some thought, I think the script is still useful, even with the 64 GiB steps in ‘total writes’ reporting. I have added a ‘-f’ option to force trimming (while still updating the recorded information) now.

Reply
Josh
July 27, 2011 at 19:54 CST
I’m puzzling over this script (I don’t know runscript). When exactly do you invoke this script?

Reply
David Lethe
July 9, 2011 at 18:41 CST
Well a few things here. First not all SSDs are created equally. With SSDs the bytes written varies in granularity. Many of the Intel SSDS have a 32GB. Some premium (SAS-connect) SSDS give you an exact cumulative read/write count down to the byte.

As for the effects of trim, it depends on HOW the writes are done, and where they are done. For example, we’ve got some SSDS that have written almost 1 Petabyte (24×7 over many, many months, nearly 100% writes in a lab. Some burned out long ago, others are still going strong WITH NEVER ANY TRIM, and only minor slow-downs. The reason we don’t need to worry about it is because we changed the app to do raw I/O to a physical device rather than filesystem I/O, and set block size appropriately.

Such generic comments are not appropriate for all models of SSDs.

Anyway, more than one way to skin a cat. Just because you take a big performance hit one way, doesn’t mean you can’t cheat the system and get your desired performance goals a different way. Plus, how do you know your benches are good in the first place? Did you even bother to bring it down to single-user mode, or monitor latency per I/O? It is quite common for LINUX systems to go off in left field for 5-10 seconds if some other app wants attention, or you get a unrecoverable read error.

Reply
Patrick
July 9, 2011 at 23:00 CST
Hi David,

thanks for commenting.

I’m aware of the fact that not all SSDs behave in the same way, which is exactly why the title of this post says “my SSD”, which is an OCZ Vertex LE with Sandforce controller, as noted in the post. So I think it should be clear that what I’m trying to say applies to this specific model.

As for your second paragraph – I guess that’s a very special way to use an SSD, for a specific purpose. I definitely like the “convenience” a file system provides 😉

And regarding your last paragraph: I think that’s what I’m saying in my post, too, isn’t it? You can either use “discard” and have the performance issues on deletion (as long as the “discard” option works as it does currently, and as long as your SSD behaves like mine), or you can choose to not use it, and instead issue the batched TRIM commands for all known free blocks whenever it’s convenient.
I think my benchmark is accurate for what I wanted to show. No, I did not switch to single-user mode, I just measured what I had observed during real use, under exactly those circumstances. I did nothing more than run ‘sync; time tar xf linux.tar; time sync; time rm -rf linux; time sync’ three times in a row, and then averaging the times (as I said in the post) – once with “discard”, once without.

Reply
JimA
November 29, 2011 at 6:58 CST
TRIM is very slow at the hardware/firmwary level because it requires a complete pipeline stall/flush cycle, and may also trigger a garbage-collection scan in the disk (see http://en.wikipedia.org/wiki/TRIM#Shortcomings). ‘

The kernel or ext4 could work around this (somewhat) by saving up TRIM commands and issuing them together at long intervals, e.g. every 15 minutes.

This is supposed to be fixed in SATA 3.1, but as of SATA III (or SATA II, like most of us have), TRIM is an “non queued” command. This means that the kernel must stop sending queued I/O requests, wait for existing ones to complete, then send the TRIM command, wait for *that* to complete, and finally resume normal I/O operations. The drive firmware also has to digest the information and persistently record the trimmed blocks somehow.

Reply
Michael Haas
February 6, 2012 at 1:48 CST
I just managed to replicate your findings on my OCZ Vertex 2 120GB (v1.22): with discard enabled, the sync following the delete of the linux tree is much slower: http://pastebin.com/mujQJMU8

Running on 3.2.2-1-ARCH on a HP 6510b, i.e. ICH7.

Reply
Sigi
July 31, 2012 at 1:41 CST
I have a HUGE difference in “fstrim” speed between my (older) Intel SSD with an Intel controller, and a newer one with a Sandforce controller.

Apparently the Sandforce controller is much slower when performing TRIM.

The “fstrim” run on the Intel controller only takes a few seconds for a 120 GB file system, improving sustained write performance by roughly 100% (as expected, and tested with bonnie++).

On the newer SSD with the Sandforce, it takes many minutes to complete for a 130 GB file system — quite in line with what you report for your OCZ SSD.

Reply
Ikem
October 30, 2012 at 12:59 CST
I bet the older SSD was SLC, were the newer SSD was MLC.

Reply
Maarten Baert
December 5, 2012 at 10:51 CST
Interesting. I just tried this on my 128MB Crucial M4 SSD, this is what I got:

maarten@laptop-maarten:/tmp$ sync; time tar -xjf linux-3.2.34.tar.bz2; time sync; time rm -rf linux-3.2.34; time sync

real	0m21.938s
user	0m21.553s
sys	0m3.608s

real	0m0.643s
user	0m0.000s
sys	0m0.024s

real	0m0.589s
user	0m0.008s
sys	0m0.556s

real	0m1.541s
user	0m0.000s
sys	0m0.020s

The unpacking is slow because I was using a compressed file rather than a simple .tar, but that wasn’t what I wanted to test so it doesn’t matter. The final sync is a bit slow, but clearly a lot faster than in your test. Better firmware I suppose?

Reply
Patrick
December 5, 2012 at 10:56 CST
Hi Maarten,

yes, better firmware is very well possible – actually I seriously hope that things have changed since I wrote that article nearly 1.5 years ago. 🙂

I should try to switch on the ‘discard’ option again with my SSD some time and re-run the test with a current kernel – maybe there are also improvements on the kernel side?

Reply
Steven Newbury
July 18, 2013 at 14:48 CST
Had the same problem with a OCZ Agility3 120GB. Turned out the problem was due to not aligning the partition with the erase blocks. Using 4MiB alignment (and also using 4k fs sectors really helps, 3x speedup!) fixed the performance/stall problems.

Reply
Patrick
July 18, 2013 at 18:56 CST
Hi Steven,

that’s very interesting. I think I tried my best to align the FS, but not sure, it’s quite a while ago. How would I check?

I do use 4k blocks, just checked with dumpe2fs.

Reply
Dan
April 28, 2015 at 5:33 CST
Good heavens! Time to bring back (and update) SpinRite.

Quick – Somebody call Steve Gibson!!

Reply
Steven Newbury
July 20, 2013 at 20:49 CST
(c)gdisk lets you set arbitrary alignments in multiples of 512. So 4k alignment is 4×1024/512 = 8, to align at 4Mb: 4x1024x1024/512 = 8192. My Agility reports 512/512 sector size which is obviously results in an insane alignment for an SSD! Although to be honest I get even worse fs performance with 512 sectors/block size on my SAMSUNG HM400JI rotational disk which also reports 512/512! Damn lying firmwares… Hopefully, newer drives actually report sensible values.

Reply
Patrick
July 20, 2013 at 21:15 CST
I see, thanks for the hint. My SSD’s firmware also seems to indicate 512 byte sectors, and my first partition (I still use MBR) seems to start at sector 63. According to your info it should instead start at sector 8192? Where did you get the information that you should have a 4 MB alignment?

Reply
Steven Newbury
July 20, 2013 at 20:50 CST
(I’m using GPT partition tables)

Reply

## original

https://patrick-nagel.net/blog/archives/337