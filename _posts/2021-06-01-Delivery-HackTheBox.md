---
layout: post
title: "Delivery - HackTheBox"
permalink: "/delivery-hackthebox"
color: rgb(7, 99, 84)
excerpt_separator: <!--more-->
author: ritiksahni
tags: [HackTheBox, Web, MySQL, Ticket Trick]
---

<center><img src="assets/img/posts/delivery-htb/blog_banner.png" alt="Delivery - Box Info"></center><br>

Delivery is an easy-rated box created by [Ippsec](https://www.youtube.com/channel/UCa6eh7gCkpPo5XXUDfygQQA). It takes us through exploiting ticket trick to gaining internal chat server access and using the disclosed credentials in the chat to login and find MySQL credentials inside the machine. We then find root hash inside MySQL database and crack using Hashcat rules.

<!--more-->

# Contents <a name="top">
* [Port Scanning](#port-scan)
* [HTTP (Port 80)](#http)
* [Port 8065 - Unknown Port](#8065)
* [Exploiting Ticket Trick](#tt)
* [Privilege Escalation](#privesc)
    * [Cracking The Hash Using Hashcat Rules](#rules)

---

# Port Scanning <a name="port-scan">

```
Nmap scan report for delivery.htb (10.10.10.222)
Host is up (0.58s latency).

PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 9c:40:fa:85:9b:01:ac:ac:0e:bc:0c:19:51:8a:ee:27 (RSA)
|   256 5a:0c:c0:3b:9b:76:55:2e:6e:c4:f4:b9:5d:76:17:09 (ECDSA)
|_  256 b7:9d:f7:48:9d:a2:f2:76:30:fd:42:d3:35:3a:80:8c (ED25519)
80/tcp   open  http    nginx 1.14.2
|_http-server-header: nginx/1.14.2
|_http-title: Welcome
8065/tcp open  unknown
| fingerprint-strings: 
|   GenericLines, Help, RTSPRequest, SSLSessionReq, TerminalServerCookie: 
|     HTTP/1.1 400 Bad Request
|     Content-Type: text/plain; charset=utf-8
|     Connection: close
|     Request
|   GetRequest: 
|     HTTP/1.0 200 OK
|     Accept-Ranges: bytes
|     Cache-Control: no-cache, max-age=31556926, public
|     Content-Length: 3108
|     Content-Security-Policy: frame-ancestors 'self'; script-src 'self' cdn.rudderlabs.com
|     Content-Type: text/html; charset=utf-8
|     Last-Modified: Sun, 31 Jan 2021 11:15:37 GMT
|     X-Frame-Options: SAMEORIGIN
|     X-Request-Id: iq8495rxpfbwxjybo8uqq3u5yh
|     X-Version-Id: 5.30.0.5.30.1.57fb31b889bf81d99d8af8176d4bbaaa.false
|     Date: Sun, 31 Jan 2021 13:00:41 GMT
|     <!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=0"><meta name="robots" content="noindex, nofollow"><meta name="referrer" content="no-referrer"><title>Mattermost</title><meta name="mobile-web-app-capable" content="yes"><meta name="application-name" content="Mattermost"><meta name="format-detection" content="telephone=no"><link re
|   HTTPOptions: 
|     HTTP/1.0 405 Method Not Allowed
|     Date: Sun, 31 Jan 2021 13:00:42 GMT
|_    Content-Length: 0
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Sun Jan 31 18:32:25 2021 -- 1 IP address (1 host up) scanned in 114.26 seconds
```

We can see there are 3 ports open:

**Port 22** - SSH (OpenSSH 7.9p1)  
**Port 80** - HTTP (nginx 1.14.2)  
**Port 8065** - Unknown Port

---

# HTTP (Port 80) <a name="http">

Accessing the website in a web browser gives us a static page with a couple of links.

![Port 80](assets/img/posts/delivery-htb/http-80.png)

It says `The best place to get all your email related support for an account check out our helpdesk` and clicking on "Helpdesk" redirects us to http://helpdesk.delivery.htb

To access it, we'll need to add the virtual host name in /etc/hosts file. (if you're on a Windows machine then add it to `c:\windows\system32\drivers\etc\hosts`)

![Helpdesk Website](assets/img/posts/delivery-htb/helpdesk.png)

It's a support ticket system and it uses OSTicket which is a customer support system ([https://osticket.com/](https://osticket.com/))

We can create support tickets and check the status of a query.

Let's create a support ticket...

![Creating a Support Ticket](assets/img/posts/delivery-htb/support_ticket.png)

Just fill in anything and click on **Create Ticket**.

![Ticket Successfully Created](assets/img/posts/delivery-htb/ticket_submitted.png)

This is where things get interesting, it says that we can check the status of our ticket using the ticket ID - 9337131.

If we want to add more messages to our support ticket, we can send an email to `TICKET-ID@delivery.htb` which in our case would be 9337131@delivery.htb

I'll get back to this but first let's check out port 8065.

# Port 8065 - Unknown Port <a name="8065">

In our port scan, we got that port 8065 is open but service couldn't be enumerated resulting in "Unknown Port" being displayed.

Let's access port 8065 in a web browser:

![Port 8065 - Mattermost](assets/img/posts/delivery-htb/8065-mattermost.png)

Port 8065 is running **Mattermost**!

Mattermost is an open-source collaboration software built for developers. It's similar to Slack, a place where people can chat and discuss.

**How do we get in?**

We can create a Mattermost account but it won't be able to send a verification email to domains that it cannot reach out.
We need to create an account with email address ending with `@delivery.htb`.

# Exploiting Ticket Trick <a name="tt">

Remember that we created a support ticket? It gave us an email address that can be used to add more information to the ticket.

That email address ended with **delivery.htb** name!

We can create a Mattermost account with the email address given by OSTicket after creating a support ticket and then check for ticket status for the verification email!

![Creating Account](assets/img/posts/delivery-htb/tt.png)

Fill in the details and click on **Create Account**.

![Response after creating account](assets/img/posts/delivery-htb/verify_message.png) 

Mattermost needs us to verify the email address. We have the option to check the ticket status, we can check the messages there and extract the verification email.

Just click on **Check Ticket Status** on helpdesk.delivery.htb and fill in the email address you used to create the ticket and the ticket ID.

![Ticket Status](assets/img/posts/delivery-htb/verify_email.png)

We can see that Mattermost sent a verification email to the support ticket address. We can copy the URL and open in another tab to verify the account.

![Verified](assets/img/posts/delivery-htb/email_verified.png)

Now we can login using the password we set and get access to the internal chat room (Mattermost)

![MM Welcome](assets/img/posts/delivery-htb/mm-welcome.png)

We get the tutorial on how to use Mattermost, we can skip it.

![Internal Chat](assets/img/posts/delivery-htb/internal_chat.png)

We've got access to the internal chats and we can see there are disclosed credentials.

Username: **maildeliverer**  
Password: **Youve_G0t_Mail!**

![SSH as maildeliverer](assets/img/posts/delivery-htb/ssh-maildeliverer.png)

SSH as maildeliverer - **We're in!**

# Privilege Escalation <a name="privesc">

I checked for active network connections via netstat and this is what I got:

![Output of Netstat](assets/img/posts/delivery-htb/netstat-result.png)

We can see that 3306 port is listening. 3306 is the standard port for **MySQL**

How do we access MySQL database? We need to find the MySQL login credentials for that.

After enumerating for a while, I found the credentials inside the configuration file of Mattermost. It is located inside `/opt/mattermost/config/config.json`

![Mattermost Configuration](assets/img/posts/delivery-htb/sql_config.png)

Username: **mmuser**  
Password: **Crack_The_MM_Admin_PW**

**Main Takeaway**: Look out for configuration files of known softwares that are running inside a machine. In many tools and applications, the important information like credentials, tokens are stored inside readable configuration files.

Let's try to login using these credentials!

![MySQL Login](assets/img/posts/delivery-htb/mysql_login.png)

I checked databases and changed the current DB to "mattermost".

![SQL Databases](assets/img/posts/delivery-htb/databases.png)

Running `show tables;` we get the following output:

![Tables in mattermost DB](assets/img/posts/delivery-htb/tables.png)

We see a table named "Users". There are many entries with hashes present in them. We can see an entry with the name "root" and we have a hash with it.

![Entry in SQL Users table](assets/img/posts/delivery-htb/root_entry_sql.png)

## Cracking The Hash Using Hashcat Rules <a name="rules">

We have a hash now that is `$2a$10$VM6EeymRxJ29r8Wjkr8Dtev0O.1STWb4.4ScG.anuu7v0EFJwgjjO`. Going back to the screenshot of internal chats in Mattermost, the user "root" indicates that a hacker can use hashcat rules to crack the hashes. Let's do the same!

But before, I'd suggest you to read [https://hashcat.net/wiki/doku.php?id=rule_based_attack](https://hashcat.net/wiki/doku.php?id=rule_based_attack) to get an understanding of how hashcat rules work.

In the chats, the user "root" said that `PleaseSubscribe!` isn't in rockyou.txt and hacker can crack the hash using rules. Let's create a wordlist with the string `PleaseSubscribe!`.

![Generating a wordlist](assets/img/posts/delivery-htb/wordlist_generate.png)

I used best64.rule file for generating the wordlist.

We got a wordlist, we can now proceed with bruteforcing the root password with the generated wordlist. 

![Cracking hash with John](assets/img/posts/delivery-htb/john-crack.png)

We successfully cracked the hash!

The password is `PleaseSubscribe!21`. We can use it to login as root in the box.

![Root Shell](assets/img/posts/delivery-htb/rootshell.png)

---

**I hope you enjoyed the write-up and learned new stuff! Feel free to message me on my socials for feedback/suggestions. [Contact Me](/contact)**

Thank you for reading!

If you liked this blog and want to support me, you can do it through my [BuyMeACoffee](https://buymeacoffee.com/ritiksahni) page!

[Back to Top](#top)