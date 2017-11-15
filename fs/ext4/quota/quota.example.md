# Implementing Disk Quotas on Linux

## Creating a Virtual Filesystem

```
$ mkdir test
$ dd if=/dev/zero of=disk-quota.ext4 count=40960
40960+0 records in
40960+0 records out
20971520 bytes (21 MB, 20 MiB) copied, 0.0932699 s, 225 MB/s
$ ls -lh
total 21M
-rw-rw-r-- 1 liminghao liminghao  20M 11月 14 15:36 disk-quota.ext4
$ mkfs.ext4 -q disk-quota.ext4 -F
$ sudo mount -o loop,rw,usrquota,grpquota disk-quota.ext4 test
$ ls -l test/
total 12
drwx------ 2 root root 12288 11月 14 15:57 lost+found
```

The "-t" gives it the type. You're not limited to ext3. In fact, you could use ext2 or other filesystems installed on your system. The "-q" is for the device, and "-F" is to force the creation without warning us that this is a file and not a block device.

## Sharing a Directory amoung Several Users

```
$ sudo groupadd quotagrp
$ sudo usermod -G quotagrp liminghao
$ sudo mkdir -p test/share
$ sudo chown -R root.quotagrp test/share
$ ls -l test/
total 13
drwx------ 2 root root     12288 11月 14 15:57 lost+found
drwxr-xr-x 2 root quotagrp  1024 11月 14 16:00 share
$ sudo chmod 2775 test/share
$ ls -l test/
total 13
drwx------ 2 root root     12288 11月 14 15:57 lost+found
drwxrwsr-x 2 root quotagrp  1024 11月 14 16:00 share
      ^---------- Note the s, setgid bit, from  chmod 2775
$ groups
liminghao adm cdrom sudo dip plugdev lpadmin sambashare
$ su - liminghao
Password:
liminghao@lmh:~$ groups
liminghao quotagrp
```

## Quotas

```
$ sudo quotacheck -cug test/
$ ls -l test/
total 26
-rw------- 1 root root      7168 11月 14 16:09 aquota.group
-rw------- 1 root root      6144 11月 14 16:09 aquota.user
drwx------ 2 root root     12288 11月 14 15:57 lost+found
drwxrwsr-x 2 root quotagrp  1024 11月 14 16:00 share
Use "edquota" to grant the user "liminghao" the desired quota.
$ sudo edquota -f test/ liminghao
```

### setquota - command line quota editor

You can also use the setquota command, which has the advantage of not using an editor making it ideal for implementing in a script. For example, to set the soft block limit to 100, a hard block limit of 200, a soft inode to 10 and a hard inode to 15 as we did above, execute the following command.

```
$ sudo setquota -u liminghao 100 200 10 15  -a /dev/loop0
$ touch share/t1
$ ln t1 t2
```

### Reports

The "repquota" command prints a summarized report. It should be run with root.

```
$ sudo repquota test
*** Report for user quotas on device /dev/loop0
Block grace time: 7days; Inode grace time: 7days
                        Block limits                File limits
User            used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
root      --      14       0       0              3     0     0
```
