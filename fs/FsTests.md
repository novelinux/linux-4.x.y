# 分布式文件系统测试方法与测试工具

非结构化数据、大数据、云存储已经毫无争议地成为了信息技术发展趋势和热点，分布式文件系统作为核心基础被推到了浪潮之巅，
广泛被工业界和学术界热推。现代分布式文件系统普遍具有高性能、高扩展、高可用、高效能、易使用、易管理等特点，
架构设计的复杂性使得系统测试也非常复杂。从商业产品ISILON, IBRIX, SONAS, Filestore, NetApp GX, Panasas, StorNext, BWFS, Loongestor，
到开源系统Lustre, Glusterfs, Moosefs，如何对这些分布式文件系统进行测试评估并选择最适合数据应用的产品系统呢？这里从功能测试和非功能测试两个方面，简要地介绍分布式文件系统的测试方法，
并对主要测试工具进行简要说明，为产品选型或产品研发提供依据。

## 分布式文件系统测试方法

###（1）功能性测试（手动＋自动化）

文件系统功能主要涉及系统实现的POSIX API，包括文件读取与访问控制、元数据操作、锁操作等功能与API。文件系统的POSIX语义不同，实现的文件系统API也不同，功能测试要能覆盖到文件系统设计实现的API和功能点。功能测试工作量大，应该重点考虑应用自动化测试方法进行，同时结合adhoc手动测试进行补充，自动化测试工具可以采用 LTP、fstest和locktests。

###（2）非功能性测试

####（2.1）数据一致性测试（手动＋自动化）

这里的数据一致性是指，文件系统中的数据与从外部写入前的数据保持一致，即写入数据与读出数据始终是一致的。数据一致性，能够表明文件系统可以保证数据的完整性，不会导致数据丢失或数据错误，这是文件系统最基本的功能。这部分测试可以应用diff, md5sum编写脚本进行自动化测试，LTP也提供了数据一致性的测试工具。另外，我们也可以进行Adhoc手动测试，比如编译软件源码、linux kernel来验证数据的完整性。

####（2.2）POSIX语义兼容性测试（自动化）

POSIX (Portable Operating System Interface)，表示可移植操作系统接口，由IEEE开发并由ANSI和ISO标准化。POSIX目的在于提高应用程序在各种OS之间的可移植性，符合POSIX标准的应用程序可以通过重新编译后运行于任何符合POSIX标准的OS上。POSIX的本质是接口，Linux是符合POSIX标准的，VFS也要符合POSIX标准。因此，文件系统只要满足VFS，就可以说符合POSIX标准，就具备了良好的可移植性、通用性和互操作性。文件系统 POSIX兼容性测试采用 LTP (Linux Test Project)和PCTS (Posix Complicance Testing Suite)进行自动化测试，支持Linux90, Linux96, UNIX98 POSIX标准测试。

####（2.3）部署方式测试（手动）

目前的分布式文件通常都具备Scale-out的特点，能够构建大规模、高性能的文件系统集群。针对不同应用和解决方案，文件系统部署方式会有显著不同。部署方式测试需要测试不同场景下的系统部署方式，包括自动安装配置、集群规模、硬件配置（服务器、存储、网络）、自动负载均衡、高可用HA等。这部分测试不大可能进行自动化测试，需要根据应用场景来设计解决方案和具体部署，然后手动进行测试。

####（2.4）可用性测试（手动）

高可用性已经是分布文件系统不可或缺的特性之一，从而保证数据应用业务的连续性。分布式文件系统可用性主要包括元数据服务MDS和数据两部分，元数据服务 MDS高可用性通常采用Failover机制或MDS集群，数据可用性主要包括Replication、Self-heal、网络簇RAID、纠删码等机制。文件系统高可用性对很多应用非常关键，需要严格进行测试和验证，这部分测试以手动方式进行。

####（2.5）扩展性测试（手动）

NIST给出的云计算权威定义：按需的自我服务，广泛的网络访问，资源池，快速的弹性能力，可度量的服务。云存储是云计算的一种形式，分布式文件系统又是云存储的基础，因此弹性扩展能力对于云计算时代的文件系统尤为重要。文件系统扩展性测试，主要包括测试系统的弹性扩展能力（扩展与回缩两方面），以及扩展系统带来的性能影响，验证是否具有线性扩展能力。这部分测试也是以手动方式进行。

####（2.6）稳定性测试（自动化）
分布式文件系统一旦上线运行，通常都是不间断长期运行，稳定性的重要性不言而喻。稳定性测试主要验证系统在长时间（7/30/180/365x24）运行下，系统是否仍然能够正常运行、功能是否正常。稳定性测试通常采用自动化方式进行，可以采用LTP、Iozone、Postmark、fio等工具对测试系统产生负载，同时使用功能测试方法验证功能的正确性。

####（2.7）压力测试（自动化）
分布式文件系统的负载能力总是存在上限的，当系统过载时，系统就有可能出现性能下降、功能异常、拒绝访问等问题。压力测试就是要验证系统在大压力下，包括数据多客户端、高OPS压力、高IOPS/吞吐量压力，系统是否仍然能够正常运行、功能是否正常、系统资源消耗情况，从而为生产运营提供依据。压力测试采用自动化方式进行，使用LTP、Iozone、Postmark、fio对系统进行持续增加压力，同时使用功能测试方法验证功能正确性，并采用top, iostat, sar, ganglia等工具对系统资源进行监控。

####（2.8）性能测试（自动化）
性能是评估一个分布式文件系统的最为关键的维度，根据文件系统在不同场景下的性能表现，可以判断文件系统是否适合特定的应用场景，并为系统性能调优提供依据。文件系统性能主要包括IOPS、OPS、吞吐量三个指标，分别表示小文件、元数据、大数据的处理能力。性能测试采用自动化方式进行，测试系统在不同负载情况下的性能，主要包括小文件、大文件、海量目录、email server、fileserver、videoserver、webserver等应用下的OPS、IOPS、吞吐量，产生IO负载的工具可采用 Iozone、Postmark、Fio、filebench等。

## 文件系统测试工具简介

### (1) LTP (http://ltp.sourceforge.net/)

LTP(Linux Test Project)是由SGI和IBM联合发起的项目，提供一套验证Linux系统可靠性、健壮性、稳定性的测试套件，也可用来进行POSIX兼容测试和功能性测试。LTP提供了2000多个测试工具，可以根据需要自行进行定制。同时，LTP还是一个优秀的自动化测试框架，基于它通过设计测试用例和测试工具可以实现更多功能的测试自动化。

### (2) fstest (http://www.tuxera.com/community/posix-test-suite/)

fstest是一套简化版的文件系统POSIX兼容性测试套件，它可以工作在FreeBSD, Solaris, Linux上用于测试UFS, ZFS, ext3, XFS and the NTFS-3G等文件系统。fstest目前有3601个回归测试用例，测试的系统调用覆盖chmod, chown, link, mkdir, mkfifo, open, rename, rmdir, symlink, truncate, unlink。

### (3) locktests (http://nfsv4.bullopensource.org/tools/tests/locktest.php)

locktest用于fcntl锁功能的压力测试。运行时，主进程先在指定文件区域设置字节范围的记录锁，然后多个从进程尝试在该文件区域执行read, write, 加新锁操作。这些操作结果是可预期的（矩阵如下），如果操作结果与预期一致则测试通过，否则测试失败。

```
 Slave type  Test operation       Master advisory locking         mandatory locking
                                                       read lock   write lock             read lock   write lock
thread      set a read lock          Allowed       Allowed               Allowed       Allowed
                  set a write lock          Allowed       Allowed               Allowed       Allowed
                                     read          Allowed       Allowed               Allowed       Allowed
                                     write         Allowed       Allowed               Allowed       Allowed
process    set a read lock        Allowed       Denied                Allowed       Denied
                   set a write lock        Denied        Denied                Denied       Denied
                                      read       Allowed       Allowed                Denied      Allowed
                                      write       Allowed       Allowed                Denied      Denied
```

### (4) PCTS (http://www.opengroup.org/testing/linux-test/lsb-vsx.html)

PCTS(Posix Complicance Testing Suite)，POSIX一致性测试套件，是从POSIX标准出发，通过严格的、定量地测试，以验证、评价、认证操作系统符合POSIX标准的程序的测试软件。IEEE std2003.1是PCTS的设计标准，常见的PCTS主要有VSX-PCTS、NIST-PCTS、OPTS-PCTS三种实现，上面提供的连接为 VSX-PCTS。

### (5) Iozone (http://www.iozone.org)

Iozone是目前应用非常广泛的文件系统测试标准工具，它能够产生并测量各种的操作性能，包括read, write, re-read, re-write, read backwards, read strided, fread, fwrite, random read, pread ,mmap, aio_read, aio_write等操作。Iozone目前已经被移植到各种体系结构计算机和操作系统上，广泛用于文件系统性能测试、分析与评估的标准工具。

### (6) Postmark (http://www.gtlib.cc.gatech.edu/pub/debian/pool/main/p/postmark/)

Postmark 是由著名的 NAS 提供商 NetApp 开发，用来测试其产品的后端存储性能。Postmark主要用于测试文件系统在邮件系统或电子商务系统中性能，这类应用的特点是：需要频繁、大量地存取小文件。 Postmark 的测试原理是创建一个测试文件池。文件的数量和最大、最小长度可以设定，数据总量是一定的。创建完成后， Postmark 对文件池进行一系列的事务（ transaction ）操作，根据从实际应用中统计的结果，设定每一个事务包括一次创建或删除操作和一次读或添加操作，在有些情况下，文件系统的缓存策略可能对性能造成影响， Postmark 可以通过对创建 / 删除以及读 / 添加操作的比例进行修改来抵消这种影响。事务操作进行完毕后， Post 对文件池进行删除操作，并结束测试，输出结果。 Postmark是用随机数来产生所操作文件的序号，从而使测试更加贴近于现实应用。输出结果中比较重要的输出数据包括测试总时间、每秒钟平均完成的事务数、在事务处理中平均每秒创建和删除的文件数，以及读和写的平均传输速度。

### (7) fio (http://freshmeat.net/projects/fio/)

fio是一个I/O标准测试和硬件压力验证工具，它支持13种不同类型的I/O引擎（sync, mmap, libaio, posixaio, SG v3, splice, null, network, syslet, guasi, solarisaio等），I/O priorities (for newer Linux kernels), rate I/O, forked or threaded jobs等等。fio可以支持块设备和文件系统测试，广泛用于标准测试、QA、验证测试等，支持Linux, FreeBSD, NetBSD, OS X, OpenSolaris, AIX, HP-UX, Windows等操作系统。

### (8) filebench (http://filebench.sourceforge.net/)

Filebench 是一款文件系统性能的自动化测试工具，它通过快速模拟真实应用服务器的负载来测试文件系统的性能。它不仅可以仿真文件系统微操作（如 copyfiles, createfiles, randomread, randomwrite ），而且可以仿真复杂的应用程序（如 varmail, fileserver, oltp, dss, webserver, webproxy ）。 Filebench 比较适合用来测试文件服务器性能，但同时也是一款负载自动生成工具，也可用于文件系统的性能。
