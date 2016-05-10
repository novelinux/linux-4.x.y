SELinux
================================================================================

历史
--------------------------------------------------------------------------------

Android的安全模型是基于一部分应用程序沙箱(sandbox)的概念, 每个应用程序都运行在自己的沙箱之中。

在Android 4.3之前的版本，系统在应用程序安装时为每一个应用程序创建一个独立的uid，基于uid来控制访问进程来访问资源，
这种安全模型是基于Linux传统 的安全模型DAC(Discretionary Access Control，翻译为自主访问控制)来实现的。

从Android 4.3开始，安全增强型Linux (SElinux)用于进一步定义应用程序沙箱的界限。作为Android安全模型的一部分，
Android使用SELinux的强制访问控制(MAC) 来管理所有的进程，即使是进程具有root(超级用户权限)的能力，SELinux
通过创建自动话的安全策略(sepolicy)来限制特权进程来增强 Android的安全性。

从Android 4.4开始Android打开了SELinux的Enforcing模式，使其工作在默认的AOSP代码库定义的安全策略(sepolicy)下。
在 Enforcing模式下，违反SELinux安全策略的的行为都会被阻止，所有不合法的访问都会记录在dmesg和logcat中。

因此，我们通过查看dmesg或者logcat, 可以收集有关违背SELinux策略的错误信息，来完善我们自己的软件和SELinux策略。
查看和设置SELinux的运行状态：

```
$ getenforce
```

返回结果有两种：Enforcing和Permissive.
* Permissive 代表SELinux关闭，不会阻止进程违反SELinux策略访问资源的行为。
* Enforcing 代表SELinux处于开启状态，会阻止进程违反SELinux策略访问资源的行为。

```
# setenforce [ Enforcing | Permissive | 1 | 0 ]
```

该命令可以立刻改变 SELinux 运行状态，在 Enforcing 和 Permissive 之间切换，结果保持至关机。注意，执行setenforce命令需要root权限。
修改某一个文件的scontext
```
$ adb shell
root@ferrari:/system/xbin # ls -Z strace
-rwxr-xr-x root     shell             u:object_r:system_file:s0 strace
root@ferrari:/system/xbin # chcon u:object_r:strace_exec:s0 strace
root@ferrari:/system/xbin # ls -Z strace
-rwxr-xr-x root shell u:object_r:strace_exec:s0 strace
```

DAC和MAC的区别：
--------------------------------------------------------------------------------

* DAC核心思想：进程理论上所拥有的权限与执行它的用户的权限相同。比如，以root用户启动Browser，那么Browser就有root用户的权限，在Linux系统上能干任何事情。

* MAC核心思想：即任何进程想在SELinux系统中干任何事情，都必须先在安全策略配置文件中赋予权限。凡是没有出现在安全策略配置文件中的权限，进程就没有该权限。

DAC和MAC的联系：
--------------------------------------------------------------------------------

Linux系统先做DAC检查，如果没有通过DAC权限检查，则操作直接失败。通过DAC检查之后，再做MAC权限检查。
SEAndroid简介

SELinux 全称 Security Enhanced Linux (安全强化 Linux)，是MAC (Mandatory Access Control，强制访问控制系统)的一个实现。其目的在于明确的指明某个进程可以访问哪些资源(文件、网络端口等)。

Android系统基于Linux实现。针对传统Linux系统，NSA开发了一套安全机制SELinux，用来加强安全性。然而，由于Android系 统有着独特的用户空间运行时，因此SELinux不能完全适用于Android系统。

为此，NSA同Google一起针对Android系统，在SELinux基础上开发了 SEAndroid。

整体框架:
--------------------------------------------------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/selinux/selinux.png

如图1所示，SEAndroid安全机制包含有内核空间和用户空间两部分支持。

1. 内核空间的selinux lsm module模块负责内核资源的安全访问控制。
2. sepolicy描述的是资源安全访问策略。系统在启动的时候，init进程会将内核空间安全访问策略加载内核空间的selinux lsm模块中去，而用户空间的安全访问策略则直接保存到普通文件中。
3. 用户空间的SecurityServer一方面需要检索用户空间的安全策略，另一方面也需要检索内核空间的安全策略。
4. 用户空间的libselinux库封装了对SELinux文件系统接口的读写操作。用户空间的SecurityServer访问内核空间的selinux lsm模块时，都是间接地通过libselinux进行的。
   用户空间的SecurityServer检索用户空间的安全策略时，同样也是通过 libselinux库来进行的。

安全策略
--------------------------------------------------------------------------------

### 安全上下文

SEAndroid是一种基于安全策略的MAC 安全机制。这种安全策略又是建立在对象的安全上下文的基础上的。这里所说的对象分为两种类型，一种称 主体（Subject），一种称为客体（Object）。主体通常就是指进程，而客观就是指进程所要访问的资源，例如文件、系统属性等。

安全上下文实际上就是一个附加在对象上的标签（label）。这个标签实际上就是一个字符串，它由四部分内容组成，分别是SELinux用户、SELinux 角色、类型、安全级别，每一个部分都通过一个冒号来分隔，格式为“user:role:type:rank”。

##### 查看一个进程的安全上下文：

```
    root@ferrari:/ # ps -Z init
    LABEL                          USER     PID   PPID  NAME
    u:r:init:s0                    root      1     0     /init
```

1. u为user的意思。SEAndroid中定义了一个SELinux用户，值为u。
2. r 为role的意思。role是角色之意，它是SELinux中一种比较高层次，更方便的权限管理思路，即 Role Based Access Control（基于角色的访问控制，简称为RBAC）。
   简单点说，一个u可以属于多个role，不同的role具 有不同的权限。
3. init，代表该进程所属的domain类型为init。
4. s0和SELinux为了满足军用和教育行业而设计的Multi-Level Security（MLS）机制有关。简单点说，MLS将系统的进程和文件进行了分级，不同级别的资源需要对应级别的进程才能访问。

##### 查看一个文件的安全上下文：

```
    root@ferrari:/ # ls -Z sepolicy
    -rw-r--r-- root     root              u:object_r:rootfs:s0 sepolicy
```

1. u：同样是user之意，它代表创建这个文件的SELinux user。
2. object_r：文件是被进程访问的，它没法扮演角色，所以在SELinux中，只能被进程访问的资源都用object_r来表示它的role。
3. rootfs：资源文件的Type，和进程的Domain其实是一个意思。它表示root目录对应的Type是rootfs。
4. s0：MLS的级别。

注意：
1.在安全上下文中，只有类型（Type）才是最重要的，SELinux用户、SELinux角色和安全级别都几乎可以忽略不计的。正因为如此，SEAndroid安全机制又称为是基于TE（Type Enforcement）策略的安全机制。
2.在SEAndroid中，只定义了一个SELinux用户u，因此我们通过ps -Z和ls -Z命令看到的所有的进程和文件的安全上下文中的SELinux用户都为u。
  同时，SEAndroid也只定义了一个SELinux角色r，因此，我们通 过ps -Z命令看到的所有进程的安全上下文中的SELinux角色都为r。

##### 用户(user)和角色(role)：

路径：external/sepolicy/users

```
    user u roles { r } level s0 range s0 - mls_systemhigh;
```

上述语句声明了一个SELinux用户u，它可用的SELinux角色为r，它的默认安全级别为s0，可用的安全级别范围为s0~mls_systemhigh，其中，mls_systemhigh为系统定义的最高安全级别。

路径：external/sepolicy/roles

```
    role r;

    role r types domain;
```

第一个语句声明了一个SELinux角色r；第二个语句允许SELinux角色r与类型domain关联。

对于进程来说，SELinux用户和SELinux角色只是用来限制进程可以标注的类型，以前面列出的 external/sepolicy/users和external/sepolicy/roles文件内容来例，如果没有出现其它的user或者 role声明，

那么就意味着只有u、r, domain 和mls 安全级别(s0 - mls_systemhigh)可以组合在一起形成一个合法的安全上下文，而其它形式的安全上下文定义均是非法的。

##### 安全级别(rank):

安全级别实际上也是一个MAC安全机制，它是建立在TE的基础之上的。在SELinux中，安全级别是可选的，也就是说，可以选择启用或者不启用。
安全级别最开始的目的是用来对政府分类文件进行访问控制的。在基于安全级别的MAC安全机制中，主体（subject）和客体（object）都关联有一 个安全级别。
其中，安全级别较高的主体可以读取安全级别较低的客体，而安全级别较低的主体可以写入安全级别较高的客体。前者称为“read down”，而后者称为“write up”。
通过这种规则，可以允许数据从安全级别较低的主体流向安全级别较高的主体，而限制数据从安全级别较高的主体流向安全级别较低的主体，从而有效地保护了数据。
注意: 如果主体和客体的安全级别是相同的，那么主体是可以对客体进行读和写的。
在实际使用中，安全级别(rank)是由敏感性(Sensitivity)和类别(Category)两部分内容组成的，格式为 “sensitivity[:category_set]”，其中，category_set是可选的。
例如，假设我们定义有s0、s1两个 Sensitivity，以c0、c1、c2三个Category，那么“s0:c0,c1”表示的就是Sensitivity为s0、Category为c0和c1的一个安全级别。

##### 类型(type):

在 SEAndroid中，我们通常将用来标注文件的安全上下文中的类型称为file_type，而用来标注进程的安全上下文的类型称为domain，
并且每一个用来描述文件安全上下文的类型都将file_type设置为其属性，每一个用来进程安全上下文的类型都将domain设置为其属性。

init进程类型定义：

路径:external/sepolicy/init.te

```
    # init switches to init domain (via init.rc).

    type init, domain;
```

这样就可以表明init描述的类型是用来描述进程的安全上下文的。

sepolicy文件类型定义：

路径：external/sepolicy/file_contexts

```
    /sepolicy        u:object_r:rootfs:s0
```

路径：external/sepolicy/file.te

```
    type rootfs, fs_type;
```

上述语句表明类型rootfs具有属性file_type，即它是用来描述文件的安全上下文的。

### 安全策略文件模块：

AOSP提供的所有Android策略文件都在路径external/sepolicy目录下面，在编译完成之后一共会生成如下个module:

##### sepolicy:

sepolicy 其主要用于配置进程的安全上下文用来控制进程访问内核资源(文件，端口等等)策略和设置虚拟文件系统的安全上下文，系统启动之后，
会由init进程在 /sys/fs /selinux中安装一个selinux虚拟文件系统，接着再加载SEAndroid安全策略到内核空间的selinux lsm模块中去。
其是由如下所示的所有te文件编译而成:

路径：external/sepolicy/Android.mk

```
sepolicy_build_files := security_classes \
                        initial_sids \
                        access_vectors \
                        global_macros \
                        mls_macros \
                        mls \
                        policy_capabilities \
                        te_macros \
                        attributes \
                        *.te \
                        roles \
                        users \
                        initial_sid_contexts \
                        fs_use \
                        genfs_contexts \
                        port_contexts
```

其中，genfs_contexts描述的是系统设置虚拟文件系统的安全上下文，例如

路径: external/sepolicy/genfs_contextfs

```
    # proc labeling can be further refined (longest matching prefix).
    genfscon proc / u:object_r:proc:s0
```

从这里可以看出将proc虚拟文件系统的安全上下文配置成u:object_r:proc:s0，
这以为这只有哪些允许访问type为proc的文件的进程才可以访问proc虚拟文件系统，也就是/proc目录下的文件。

##### file_contexts:

file_contexts模块用于设置打包在ROM里面的文件的安全上下文。其是由external/sepolicy/file_contexts文件编译而成。
例如在build systemimage时会将这个file_contexts文件路径传递给命令make_ext4fs时，就会根据它设置的规则给打包在 system.img里面的文件关联安全上下文。
这样我们就获得了一个关联有安全上下文的system.img镜像文件了。
这样通过fastboot命令将system.img刷入system分区mount到/system目录之后，因为设置了相应的安全上下文，这样就能控制进程访问system目录下相关文件.

##### seapp_contexts和mac_permissions.xml:

seapp_contexts是负责设置APP数据文件的安全上下文，mac_permissions.xml是负责设置APP进程的安全上下文.

路径: external/sepolicy/mac_permissons.xml

```
    <?xml version="1.0" encoding="utf-8"?>
    <policy>
        <!-- Platform dev key in AOSP -->
        <signer signature="@PLATFORM" >
          <seinfo value="platform" />
        </signer>

        <!-- All other keys -->
        <default>
          <seinfo value="default" />
        </default>

    </policy>
```

文件mac_permissions.xml给不同签名的App分配不同的seinfo字符串，例如，在AOSP源码环境下编译并且使用平台签名的App获得的seinfo为“platform”，使用第三方签名安装的App获得的seinfo签名为"default"。
这个seinfo描述的是其实并不是安全上下文中的Type，它是用来在另外一个文件seapp_contexts中查找对应的type的。

路径：external/sepolicy/seapp_contexts

```
    isSystemServer=true domain=system_server
    user=system domain=system_app type=system_app_data_file
    user=bluetooth domain=bluetooth type=bluetooth_data_file
    user=nfc domain=nfc type=nfc_data_file
    user=radio domain=radio type=radio_data_file
    user=shared_relro domain=shared_relro
    user=shell domain=shell type=shell_data_file
    user=_isolated domain=isolated_app
    user=_app seinfo=platform domain=platform_app type=app_data_file
    user=_app domain=untrusted_app type=app_data_file
```

例如，对于使用平台签名的App来说，它的seinfo为“platform”。用户空间的SecurityServer(比如installd)在为它查找 对应的Type时，使用的user输入为"_app"。这样在seapp_contexts文件中，与它匹配的一行即为：

```
    user=_app seinfo=platform domain=platform_app type=app_data_file
```

这样我们就可以知道，使用平台签名的App所运行在的进程domain为“platform_app”，并且它的数据文件的file_type为“app_data_file”。
应用程序安装服务PackageManagerService在启动的时候，会在/system/etc/security目录中找到 mac_permissions.xml文件，然后对它进行解析，
得到App签名或者包名与seinfo的对应关系。当 PackageManagerService安装App的时候，
它就会根据其签名或者包名查找到对应的seinfo，并且将这个seinfo传递给另外一 个守护进程installed。守护进程installd负责创建App数据目录。
在创建App数据目录的时候，需要给它设置安全上下文，使得 SEAndroid安全机制可以对它进行安全访问控制。

installd根据PackageManagerService传递过来的 seinfo，并且调用libselinux库提供的selabel_lookup函数到seapp_contexts文件中查找到对应的type。
有了这个Type之后，installd就 可以调用libselinux库提供的lsetfilecon函数来给正在安装的App的数据目录设置安全上下文了。

##### property_contexts:

在Android系统中，有一种特殊的资源——属性，App通过读写它们能够获得相应的信息，以及控制系统的行为，因此，SEAndroid也需要对它们进行保护。这意味着Android系统的属性也需要关联有安全上下文。

路径：external/sepolicy/property_contexts

```
    ##########################
    # property service keys
    #
    #
    net.rmnet               u:object_r:net_radio_prop:s0
    net.gprs                u:object_r:net_radio_prop:s0
    net.ppp                 u:object_r:net_radio_prop:s0
    ...
```

属性的安全上下文与文件的安全上下文是类似的，将属性net.rmnet设置为u:object_r:net_radio_prop:s0， 意味着只有有权限访问type为net_radio_prop的资源的进程才可以访问这个属性。

##### service_contexts:

在AndroidL系统中，还将服务(属于进程或线程)也作为一种资源来定义，给其定义对应的安全上下文，用来保护服务不被恶意进程访问.

路径：external/sepolicy/service_contexts

```
    ...
    window                                    u:object_r:system_server_service:s0
    *                                         u:object_r:default_android_service:s0
```

服务的安全上下文同样与文件的安全上下文是类似的，将window服务设置为u:object_r:system_server_service:s0，意味着只有有权限访问type为system_server_service的资源的进程才可以访问这个服务。

### 配置实例：

接下来我们以miui自带的服务shelld为例来描述如何给其配置安全上下文，使其能够正常工作。
shelld: 这是一个使用binder通讯的binder服务，其是从init进程fork出来运行的进程.
我们给shelld配置的相关SEAndroid的安全上下文如下te文件所示：

路径：miui/device/common/sepolicy/common/file_contexts

```
    /system/xbin/shelld     u:object_r:shelld_exec:s0
```

如上所示te语句表明，将/system/xbin/shelld文件在打包system.img时设置安全上下文为u:object_r:shelld_exec:s0，
用于保护其不被别的进程可以随意调用执行/system/xbin/shelld, 只有具有权限执行type为shelld_exec的进程才可以执行shelld.

为了使其能够添加到servicemanager中去并且能够访问系统资源，我们作了如下配置：

路径：miui/device/common/sepolicy/common/shelld.te

```
    # shelld
    type shelld, domain;                                    # 设置shelld属于domain域，是一个进程的type
    type shelld_exec, exec_type, file_type;       # 设置shelld_exec属于可执行文件的类型.
    typeattribute shelld mlstrustedsubject;        # 设置shelld是一个可信任的主题

    # init_daemon_domain是定义在external/sepolicy/te_macros中的一个宏，如果没有设置该条语句当shelld 从init进程fork出来执行后，shelld会被设置成和init进程拥有一模一样的安全上下文，其拥有和init进程一样的权限
    # 设置之后，则当其从init进程fork出来之后，将被设置成shelld.te为shelld进程配置的安全上下文，其拥有同init进程不一样的权限.
    init_daemon_domain(shelld)

    #domain_auto_trans 也是定义在external/sepolicy/te_macros中的一个宏，设置了如下语句之后，表明shelld进程fork出shell进程来通 过exec执行shell程序时，shell程序将使用其自身的安全上下文，而不是shelld的
    domain_auto_trans(shelld, shell_exec, shell)

    #unix_socket_connect同样是定义在external/sepolicy/te_macros中的一个宏，设置完如下语句，表明shelld进程可以通过socket同本地服务进行通讯.
    unix_socket_connect(shelld, property, init);

    #binder_use宏表明shelld可以使用Binder同servicemanager进程进行IPC通讯
    binder_use(shelld)

    #binder_call允许shelld同对应domain的Binder服务端进程进行binder IPC通讯
    binder_call(shelld, binderservicedomain)
    binder_call(shelld, appdomain)

    #binder_service宏表明shelld是Binder通讯的服务端进程
    binder_service(shelld)

    #如下语句允许shelld进程来设置自身DAC控制系统权限
    allow shelld self:capability
        { setgid setuid dac_override chown fowner fsetid };

    ...

    #如下语句表明允许scontext=shelld的shelld进程来访问tcontext=system_app_data_file安全上下文的目录和文件
    # /data/data subdirectory for system UID apps.
    allow shelld system_app_data_file:dir create_dir_perms;
    allow shelld system_app_data_file:file create_file_perms;
    ...

    # shell

    #如下语句表明允许shelld进程可以执行type为shell_exec的文件
    allow shelld shell_exec:file { rx_file_perms };
    ...
    #如下语句允许shelld进程将shelld_service添加到servicemanager进程中去
    allow shelld shelld_service:service_manager add;
```

shelld_service是一种service的安全上下文，其定义如下所示：

路径：miui/device/common/sepolicy/common/service_contexts

```
    miui.shell        u:object_r:shelld_service:s0 #该条语句将名称为miui.shell的binder进程设置安全上下文为 u:object_r:shelld_service:s0
```

在将shelld_service设置为service_manager_type属性

路径：miui/device/common/sepolicy/common/service.te

```
    type shelld_service,        service_manager_type; #该条语句将shelld_service表明为一个service_manager_type的属性，具有这个属性的service才能够添加到 servicemanager中去.
```

进行了如下配置之后，再将如下添加到Makefile中的变 量BOARD_SEPOLICY_UNION，并将这些te配置文件所在的目录名称添加到BOARD_SEPOLICY_DIRS变量中，
则运行命令$ make bootimage, 就能将对应的安全策略文件build进boot.img中
在重启之后就能够由init进程加载到内核中去.
或者可以将生成的sepolicy文件push到/data/security/current/sepolicy之后接着调用$ setprop selinux.reload_policy 1，使得init重新加载sepolicy，由于/data目录下有了sepolicy，所以它将使用这个新的。

### 为违反SEAndroid策略的进程配置安全上下文：

一般如果有进程违反SEAndroid策略，我们将在logcat或者dmesg中发现如下类似的log:

```
    <12>[   12.835933] type=1400 audit(1325843.199:6): avc: denied { write } for pid=295 comm="installd" name="/" dev="mmcblk0p35" ino=2 scontext=u:r:installd:s0 tcontext=u:object_r:cache_file:s0 tclass=dir permissive=0
```

这样我们可以直接到对应的installd进程的安全策略文件中去添加如下类似语句就能够消除对应的违反规则：

路径：external/sepolicy/installd.te

```
    allow installd cache_file:dir { write };
```

其中，installd就是log中scontext=u:r:installd:s0表明的domain主体安全上下文，cache_file就是log中tcontext=u:object_r:cache_file:s0的客体安全上下文，客体的类型是tclass=dir表明的dir类型，违反的规则是{ write }。