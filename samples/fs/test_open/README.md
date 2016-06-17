open
========================================

src
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/samples/open/open.c

result
----------------------------------------

```
root@gemini:/ # /data/local/tmp/open /cache/test.txt
root@gemini:/ # ls -l /cache/test.txt
-rw-r--r-- root     root            0 2016-06-17 07:15 test.txt
root@gemini:/ # stat /cache/test.txt
  File: `/cache/test.txt'
  Size: 0        Blocks: 0       IO Blocks: 4096        regular empty file
Device: 80dh      Inode: 11       Links: 1
Access: (644/-rw-r--r--) Uid: (0/    root)      Gid: (0/    root)
Access: 2016-06-17 07:15:45.179439339
Modify: 2016-06-17 07:15:45.179439339
Change: 2016-06-17 07:15:45.179439339
```
