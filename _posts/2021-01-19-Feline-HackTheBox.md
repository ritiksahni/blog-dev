---
layout: post
title: "Feline - HackTheBox"
color: rgb(130, 10, 34)
permalink: "/passage-hackthebox"
excerpt_separator: <!--more-->
author: ritiksahni
tags: [HackTheBox, Docker, API, Deserialization]
---

Feline is a super fun box created by MinatoTW and MrR3boot, two hackers I admire a lot for their work. This box takes us through exploiting a java deserialization in a custom web application hosted on an Apache Tomcat server to exploiting an RCE in SaltStack to gain a shell inside a docker container, and finally getting root on host by exploiting an exposed docker.sock file.

<!--more-->
## Port Scanning

```
# Nmap 7.80 scan initiated Sun Jan 17 06:38:48 2021 as: nmap -sV -sC -sT -p 22,8080 -oA nmap/initial 10.10.10.205
Nmap scan report for 10.10.10.205
Host is up (0.28s latency).

PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 8.2p1 Ubuntu 4 (Ubuntu Linux; protocol 2.0)
8080/tcp open  http    Apache Tomcat 9.0.27
|_http-open-proxy: Proxy might be redirecting requests
|_http-title: VirusBucket
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Sun Jan 17 06:39:02 2021 -- 1 IP address (1 host up) scanned in 14.18 seconds
```

We can see that there are 2 ports open, first is SSH on port 22 and the second is HTTP on port 8080 which has Apache Tomcat 9.0.27 running.

Let's take a look at the web server at port 8080

## Web (Port 8080)

Opening http://10.10.10.205:8080/ serves a website