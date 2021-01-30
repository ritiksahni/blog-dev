---
layout: post
title: "Introduction to Linux Filesystems"
permalink: "/linux-filesystem"
color: rgb(100, 8, 112)
excerpt_separator: <!--more-->
author: ritiksahni
tags: [Linux, Guide]
---

Hey! This article will explain you things you need to know about the Linux filesystems in an introductory and high-level manner. We will learn the hierarchy of modern days linux filesystem and interesting things to keep in mind during pentesting and other fields of work.

<!--more-->
<center><iframe src="https://giphy.com/embed/3ohhwyXhrNXmL831XG" width="480" height="269" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/go-come-now-3ohhwyXhrNXmL831XG"></a></p></center>


## Contents <a name="top">
* [About Filesystems](#about-fs)
    * [Filesystem Properties](#fs-props)
* [Aspects of filesystem](#fs-aspects)
* [Virtual File System](#vfs)
* [Directory Structure](#directory-structure)
    * [Understanding the Structure](#understanding-structure)
* [Magical /proc](#magical-proc)
* [Mounting](#mounting)
* [Other Filesystems](#other-fs)

---

## About Filesystems <a name="about-fs">

Linux supports several filesystems including **ext2, ext3, ext4, xfs, btrfs, squashfs** and many more.

These filesystems provides some basic functionality like storing data under a well-structured hierarchy of directories and files, defining access rights and permissions, system calls to interact with the filesystem objects like files and directories.

In the modern days, the most used filesystem among the majority of linux systems is **EXT4 (Fourth Extended File System)**, it is the default filesystem for distributions like Debian and Ubuntu. It is also the latest filesystem from the ext* family. From the previous versions, EXT4 offers better performance and reliability, reduced fragmentation, faster interactive repairs (fsck). EXT4 was started from Linux Kernel 2.6.19.

#### Filesystem Properties <a name="fs-props">

- Storage: A structured space to store non-volatile data. The most important property of filesystems.
- Namespace: A naming methodology and rules for structuring data.
- Security Model: A scheme for controlling and defining access controls, permissions.
- API: System function calls to interact with files, directories in a system.
- Implementation: A software to implement the above properties.

---

## Aspects of Filesystem <a name="fs-aspects">

![ext4-illustration](assets/img/posts/linux-fs/ext4_image.png)

- **Filesystem API**  

Different filesystems require API (Application Programming Interface) to interact with the objects in a system like various available files and directories. Such APIs provide a way to create, move, rename, edit, delete and do more such things inside a filesystem.

You can get more information about the API calls from [https://www.kernel.org/doc/html/v4.14/filesystems/index.html#linux-filesystems-api](https://www.kernel.org/doc/html/v4.14/filesystems/index.html#linux-filesystems-api)

- **Superblock**

The first block of the partition contains metadata or the information required to organize the data structurally based on the filesystem. This block is known as the Superblock. In web applications, the way HTTP headers are above the body, and consist of important information, the same way superblock is the block of important data and it comes first in a partition.

- **File naming structure**  

Every file we see has a name to it, it obviously helps us identify and distinguish between different files. However, there can be certain limitations over naming a file or directory in a filesystem. Some filesystems allow case-sensitive naming and some don't. In that case, `abc` and `AbC` would be 2 different directories or files even if there's just the difference of letter cases.

- **Metadata**  

The filesystem may store data such as file creation time, file modification date, last accessed, permissions, file attributes (read/write), content length, filename etc. Some file systems provide for user-defined attributes such as the author of the document, the character encoding of a document or the size of an image.

- **Integrity**  

The filesystem is also responsible for maintaining the integrity of the files by ensuring if any file in the filesystem terminates/behaves abnormally and updating metadata or the contents. The filesystem must also create logs in case of different activities or errors being occurred.

- **Management of Data**  

A key purpose of the filesystem is to allow a user to interact with the data within the system. The written data is continuously collected in the form of bytes and stored in an efficient manner and retrieves data from the filesystem in case a user tries to read it.

- **Inodes**  

Inodes are very simple to understand and are important in filesystems. It stands for `Index Nodes` and is a data structure containing the attributes of files and directories along with the location of the data in the disk block. It simply points to the data.

---

## Virtual File System (VFS) <a name="vfs">

It is a layer on top of a proper filesystem, it gives client applications a way to access the files just the way it's done with filesystems like EXT4.

A system having multiple filesystems can have a VFS which will further interpret all the syscalls (like read, write, delete) and gives the client applications a way to interact with different filesystems having VFS as a common interface.


Here is an illustration of the same (Credits: [https://opensource.com](https://opensource.com))

![vfs](assets/img/posts/linux-fs/vfs.png)

We can see that VFS is communicating with different filesystems.

**Filesystems accessed remotely are called as NFS (Network File System)**

---

## Directory Structure <a name="directory-structure">

We will understand the directory structure of Linux systems. You can use a utility called `tree` which gives a hierarchical structure of the directories as well as present files.

**Installing `tree`**
```bash
# Ubuntu / Debian distros
sudo apt install tree

# Red Hat / Fedora based distros
sudo dnf install tree

# SUSE / OpenSUSE based distros
sudo zypper install tree

# Those who tweet "I use arch btw"
sudo pacman -S tree

```
Using `tree` to see the structure of /
```bash
deep@myubuntu:~$ tree -L 1 /
/
├── bin -> usr/bin
├── boot
├── cdrom
├── dev
├── etc
├── home
├── lib -> usr/lib
├── lib32 -> usr/lib32
├── lib64 -> usr/lib64
├── libx32 -> usr/libx32
├── lost+found
├── media
├── mnt
├── opt
├── proc
├── root
├── run
├── sbin -> usr/sbin
├── snap
├── srv
├── sys
├── tmp
├── usr
└── var
```

This represents the / (root) directory of the filesystem, let's understand each of these directories and their purpose.

#### Understanding the Structure <a name="understanding-structure">

__/bin__  

It contains the system binaries to run different programs and applications. Some important binaries like `cat`, `ls`, `mv`, `rm` etc. are located in this directory. The system binaries in this directory simply help us to navigate through the system and perform activities.

__/boot__

It contains the files which a system requires for booting up. Messing up with one of the files in this directory is **not recommended** as it can lead to problems while booting up your operating system.

__/dev__

<em>In Linux, everything is a file.</em> This directory consists of <em>device</em> files. By that I mean, the files which provide an interface for the user to interact with the connected hardware devices like USB drives, webcams, printers, etc. These interfaces are present in /dev directory as if they are regular files. 

__/etc__

In the early days, it literally used to mean **et cetera** and its purpose was to allow everyone to store files that didn't quite belong to anywhere else on the system.

Now its usage has been changed to only store configuration files of applications across the system and not to store any binaries. Files containing system information, password hashes, users information is usually stored in /etc

__/home__

This place has the personal directories of every user on the system. If there's a user on the system with the name `Ritik` then there's a high probability there will be a directory `/home/ritik` containing all the user files.

__/lib__

This directory consists of all the libraries, these libraries are used by the programs in the system to run properly. Libraries simply contain code to support the applications to run.

__/lost+found__

This directory is mainly used by `fsck`. All the corrupted data found by [fsck](https://linux.die.net/man/8/fsck) is placed in this directory /lost+found.

__/media__

When we plug in external devices such as USB drives, external SSDs, all the data present in those devices are mounted in this directory while they are plugged in.

__/mnt__

In case we wanna mount any storage device or share manually then we usually do it in this directory. I have covered "Mounting" in this blog and you'll study it further below.

__/opt__

/opt is an optional directory, some applications use it for installations, but mostly those which provide compartmentalized installation, applications that are integrated into the system aren't usually in this folder

__/proc__

It is a [virtual filesystem](#vfs), it can give us some general information about the system in realtime such as CPU, kernel information.

We will explore some interesting specifics about it further in this blog post.

__/run__

This directory is utilized by storing temporary files like PID files and communication socket endpoints.

__/root__

It is the home directory for the root user or the "Administrator" of the Linux system. All of the files of the root user will be stored in this directory as every users' home directories are separate.

__/sbin__

The binaries used for system administration are stored here, the binaries in this directory are supposed to be used by the root user only.

__/usr__

In older Unix implementations, the home directories of users were stored in /usr but these days /home has taken that place and /usr is now used to store data of programs & applications, wallpapers, libraries, documents, etc.

__/srv__

The data which has to be served through different protocols like HTTP, FTP, RSYNC is stored here. Example: FTP hosted data can be stored in /srv/ftp/

__/sys__

This is another [virtual filesystem](#vfs) like /proc and it contains information of devices connected to the system. Many files in this directory can be used to directly interact with the devices and manipulate stuff like change brightness, changing CPU speed, etc.

__/tmp__

It contains temporary files that the applications might be using in the realtime and it is not necessary that the data in this directory is important or has to be used. All the data inside this directory is deleted once a system reboots.

__/var__

Applications stores some of the data in /var during its operation at a time. Example: Apache2 can store log files in /var/log/apache2

## Magical /proc <a name="magical-proc">

`/proc` is a virtual filesystem in Linux. `/proc` can be a very interesting place to look for juicy information. <em>In Linux, everything is a file</em> and this directory emphasizes on that.  /proc contains information about the system, CPU, processes and is completely dynamic, the data isn't technically stored into it but reveals real-time data through pointing towards it.

Inside `/proc` there are files associated with the processes in the realtime. If a process is running with the ID of 1337 then there must be a place `/proc/1337/` in the system. The endpoint further contains files required to fetch the actual information about the specified process.

```bash
nasahacker@withHTML:/proc/1337$ ls
arch_status  auxv        cmdline          cpuset   exe     gid_map  loginuid   mem        mountstats  numa_maps  oom_score_adj  personality  sched      setgroups     stack  status   timers         wchan
attr         cgroup      comm             cwd      fd      io       map_files  mountinfo  net         oom_adj    pagemap        projid_map   schedstat  smaps         stat   syscall  timerslack_ns
autogroup    clear_refs  coredump_filter  environ  fdinfo  limits   maps       mounts     ns          oom_score  patch_state    root         sessionid  smaps_rollup  statm  task     uid_map
```


Let's understand some of these files within /proc :

| Endpoint                  | Description |
| :---                      | :---        |
| /proc/\[PID\]/cmdline             | It gives the exact command which was used to invoke the process. It can sometimes help us understand the exact configuration for that process by understanding the arguments placed            |
| /proc/\[PID\]/stat                | It gives us statistics about the process. Refer to [this StackOverflow answer](https://stackoverflow.com/a/60441542) for a detailed explanation of the format of its output.
| /proc/\[PID\]/environ             | It tells us the environment variables with which the process is running.
| /proc/\[PID\]/cwd                 | It's a symlink to the current working directory.
| /proc/\[PID\]/mountinfo           | Displays mount information of a process.
| /proc/\[PID\]/io                  | It contains input/output information of a process.

There are also some directories within /proc/\[PID\] such as **`/proc/\[PID\]/net`** which gives network information (it can be helpful during the reconnaissance of the network), **`/proc/\[PID\]/map_files`** which contains information about the **memory mapped files** and has entries named by memory region start and end address pair (e.g 7f4dd6136000-7f4dd6137000) and symlinks to the actual libraries.


There are way many different places to look for, in /proc but covering all of them in this article would be a bad idea. You can get more detailed information about all of them from here: [https://man7.org/linux/man-pages/man5/procfs.5.html](https://man7.org/linux/man-pages/man5/procfs.5.html)

**Conclusion: Checking all the processes and /proc entries related to specific processes can be extremely helpful during pentests, CTFs etc. for any type of information gathering.**

---
## Mounting <a name="mounting">


We're learning about filesystems in this article, we probably should also know about <em>mounting</em> filesystems, isn't it? Before that, we need to know about <em>block devices.</em>

In the Unix world, a block device is simply a thing that represents some sort of **data** that can be read or written in blocks. They are often astorage devices of some kind like a USB drive or an external SSD disk.

Back to mounting... it is a simple process of making a filesystem or a block device accessible and readable at a certain directory. It does not matter if it is a filesystem or a block device, we can mount it easily.

We can use `mount` command to mount a filesystem or a block device and `umount` to unmount.

Example: If you have connected a USB drive to the machine and it's name is `/dev/sdb` (linux keeps it that way) then we can mount it to any of our own directory with the following command:

```bash
mkdir /mnt/usb-drive-mount
mount /dev/sdb /mnt/usb-drive-mount
cd /mnt/usb-drive-mount

# We can now see all the contents of the USB device in /mnt/usb-drive-mount
ls
```

Please note that this mounted data will be there as long as the USB drive is connected to the system or until we manually unmount it using:

```bash
umount /mnt/usb-drive-mount
```
---

## Other Filesystems <a name="other-fs">

So far in this article, we have discussed mostly the EXT4 filesystem as it's our modern-day filesystem and we encounter it probably every day if we use Linux but there are some other famous filesystems which we should know about at least a little so let's dive into it!

- **XFS** - Developed in 1994, it has some features like file fragmentation with delayed allocation. It is very efficient with large files but can create performance problems with small files.

- **BTRFS** - Developed in 2009, Stands for B-Tree File System and has features like snapshots, resizing and defragmentation, transparent compression.

- **ZFS** - Developed in 2001, this has features like snapshots, pooled storage, data scrubbing, simple administration etc.

- **SquashFS** - Developed in 2002, it is a read-only filesystem that compresses data such as inodes, files, directories etc. It supports several compression algorithms.

---

**I hope you enjoyed reading this article and learned about filesystems, feel free to message me on my Twitter/Discord for feedback, suggestions, or questions! [Contact Me](/contact)**

<br><br>
#### References
You can read the following references for detailed information on each of the topics.

[https://en.wikipedia.org/wiki/Inode](https://en.wikipedia.org/wiki/Inode)  
[https://medium.com/@emmanuelbashorun/linux-file-system-virtual-file-system-vfs-layer-part-3-79235c40a499](https://medium.com/@emmanuelbashorun/linux-file-system-virtual-file-system-vfs-layer-part-3-79235c40a499)  
[https://opensource.com/life/16/10/introduction-linux-filesystems](https://opensource.com/life/16/10/introduction-linux-filesystems)  
[https://www.javatpoint.com/linux-file-system](https://www.javatpoint.com/linux-file-system)  
[https://opensource.com/article/17/5/introduction-ext4-filesystem](https://opensource.com/article/17/5/introduction-ext4-filesystem)  


[Back to Top](#top)
