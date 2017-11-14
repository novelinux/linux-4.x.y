# Disk Quotas

Disk space can be restricted by implementing disk quotas which alert a system administrator before a user consumes too much disk space or a partition becomes full.

Disk quotas can be configured for individual users as well as user groups. This makes it possible to manage the space allocated for user-specific files (such as email) separately from the space allocated to the projects a user works on (assuming the projects are given their own groups).

In addition, quotas can be set not just to control the number of disk blocks consumed but to control the number of inodes (data structures that contain information about files in UNIX file systems). Because inodes are used to contain file-related information, this allows control over the number of files that can be created.

## Configuring Disk Quotas

To implement disk quotas, use the following steps:

Enable quotas per file system by modifying the /etc/fstab file.

Remount the file system(s).

Create the quota database files and generate the disk usage table.

Assign quota policies.

Each of these steps is discussed in detail in the following sections.

### Enabling Quotas

As root, using a text editor, edit the /etc/fstab file. Add the usrquota and/or grpquota options to the file systems that require quotas:

```
/dev/VolGroup00/LogVol00 /         ext3    defaults        1 1
LABEL=/boot              /boot     ext3    defaults        1 2
none                     /dev/pts  devpts  gid=5,mode=620  0 0
none                     /dev/shm  tmpfs   defaults        0 0
none                     /proc     proc    defaults        0 0
none                     /sys      sysfs   defaults        0 0
/dev/VolGroup00/LogVol02 /home     ext3    defaults,usrquota,grpquota  1 2
/dev/VolGroup00/LogVol01 swap      swap    defaults        0 0 . . .
```

In this example, the /home file system has both user and group quotas enabled.

**Note**:
The following examples assume that a separate /home partition was created during the installation of Red Hat Enterprise Linux. The root (/) partition can be used for setting quota policies in the /etc/fstab file.

### Remounting the File Systems

After adding the usrquota and/or grpquota options, remount each file system whose fstab entry has been modified. If the file system is not in use by any process, use one of the following methods:

Issue the umount command followed by the mount command to remount the file system.(See the man page for both umount and mount for the specific syntax for mounting and unmounting various filesystem types.)

Issue the mount -o remount <file-system> command (where <file-system> is the name of the file system) to remount the file system. For example, to remount the /home file system, the command to issue is mount -o remount /home.

If the file system is currently in use, the easiest method for remounting the file system is to reboot the system.

### Creating the Quota Database Files

After each quota-enabled file system is remounted, the system is capable of working with disk quotas. However, the file system itself is not yet ready to support quotas. The next step is to run the quotacheck command.

The quotacheck command examines quota-enabled file systems and builds a table of the current disk usage per file system. The table is then used to update the operating system's copy of disk usage. In addition, the file system's disk quota files are updated.

To create the quota files (aquota.user and aquota.group) on the file system, use the -c option of the quotacheck command. For example, if user and group quotas are enabled for the /home file system, create the files in the /home directory:

```
$ quotacheck -cug /home
```

The -c option specifies that the quota files should be created for each file system with quotas enabled, the -u option specifies to check for user quotas, and the -g option specifies to check for group quotas.

If neither the -u or -g options are specified, only the user quota file is created. If only -g is specified, only the group quota file is created.

After the files are created, run the following command to generate the table of current disk usage per file system with quotas enabled:

```
$ quotacheck -avug
```

The options used are as follows:

a — Check all quota-enabled, locally-mounted file systems

v — Display verbose status information as the quota check proceeds

u — Check user disk quota information

g — Check group disk quota information

After quotacheck has finished running, the quota files corresponding to the enabled quotas (user and/or group) are populated with data for each quota-enabled locally-mounted file system such as /home.

### Assigning Quotas per User

The last step is assigning the disk quotas with the edquota command.

To configure the quota for a user, as root in a shell prompt, execute the command:

```
edquota username
```

Perform this step for each user who needs a quota. For example, if a quota is enabled in /etc/fstab for the /home partition (/dev/VolGroup00/LogVol02 in the example below) and the command edquota testuser is executed, the following is shown in the editor configured as the default for the system:


Disk quotas for user testuser (uid 501):

```
Filesystem                blocks     soft     hard    inodes   soft   hard
/dev/VolGroup00/LogVol02  440436        0        0     37418      0      0
```

Note
The text editor defined by the EDITOR environment variable is used by edquota. To change the editor, set the EDITOR environment variable in your ~/.bash_profile file to the full path of the editor of your choice.
The first column is the name of the file system that has a quota enabled for it. The second column shows how many blocks the user is currently using. The next two columns are used to set soft and hard block limits for the user on the file system. The inodes column shows how many inodes the user is currently using. The last two columns are used to set the soft and hard inode limits for the user on the file system.

The hard block limit is the absolute maximum amount of disk space that a user or group can use. Once this limit is reached, no further disk space can be used.

The soft block limit defines the maximum amount of disk space that can be used. However, unlike the hard limit, the soft limit can be exceeded for a certain amount of time. That time is known as the grace period. The grace period can be expressed in seconds, minutes, hours, days, weeks, or months.

If any of the values are set to 0, that limit is not set. In the text editor, change the desired limits. For example:

Disk quotas for user testuser (uid 501):   Filesystem                blocks     soft     hard   inodes   soft   hard   /dev/VolGroup00/LogVol02  440436   500000   550000    37418      0      0
To verify that the quota for the user has been set, use the command:

quota testuser
7.1.5. Assigning Quotas per Group

Quotas can also be assigned on a per-group basis. For example, to set a group quota for the devel group (the group must exist prior to setting the group quota), use the command:

edquota -g devel
This command displays the existing quota for the group in the text editor:


Disk quotas for group devel (gid 505):
Filesystem                blocks    soft     hard    inodes    soft    hard
/dev/VolGroup00/LogVol02  440400       0        0     37418       0       0


Modify the limits, then save the file.

To verify that the group quota has been set, use the command:

quota -g devel
7.1.6. Setting the Grace Period for Soft Limits

If soft limits are set for a given quota (whether inode or block and for either users or groups) the grace period, or amount of time a soft limit can be exceeded, should be set with the command:

edquota -t
While other edquota commands operate on a particular user's or group's quota, the -t option operates on every filesystem with quotas enabled.