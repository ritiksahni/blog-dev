---
layout: post
title: "6 Interesting Honeypots You Should Know About!"
color: rgb(100, 13, 45)
permalink: "/6-interesting-honeypots-you-should-know-about"
excerpt_separator: <!--more-->
author: ritiksahni
tags: [Honeypot, Defense, Blue Team]
---

Honeypots can be extremely useful for you to detect suspicious activities from the bad guys. If you are managing applications of any nature, you should consider deploying honeypots.

<!--more-->

# Contents <a name="top">
* [What is a Honeypot?](#what)
* [Types of honeypots](#type)
* [6 AWESOME Honeypots](#honeypots-list)

---

# What is a honeypot? <a name="what">

In computer security, honeypots are developed to attract hackers to attack internet infrastructure.

**Why attract the bad guys?**

To understand threats, attacks that come from the bad hackers! Honeypots are made attractive to make the infrastructure enticing for hackers to attack.

Honeypots appear like real computer systems and software but in reality, they are there to trap the bad guys. It's a dead-end.

In some cases, they are meant to distract the hackers from the real targets that can be attacked. As the honeypots are dead-ends, hackers don't get anything in return after attacking them.

# 6 AWESOME Honeypots! <a name="honeypots-list">


- [django-admin-honeypot](https://github.com/dmpayton/django-admin-honeypot)

If you're managing a Django based application, using this honeypot can be really beneficial as Django login panels are very interesting to hackers and having a fake login panel can be very handy for catching the bad guys and their suspicious activities.

> django-admin-honeypot is a fake Django admin login screen to log and notify admins of attempted unauthorized access. This app was inspired by discussion in and around Paul McMillan's security talk at DjangoCon 2011.

---

- [tomcat-manager-honeypot](https://github.com/helospark/tomcat-manager-honeypot)

If you're managing an application that is running on Apache Tomcat server then you should consider using this honeypot. This honeypot mimics the manager endpoints of Tomcat and logs requests, saves attackers' WAR files for analysis.

Tomcat Manager is used to control the web server through a web application and its endpoints.

---

- [mysql-honeypotd](https://github.com/sjinks/mysql-honeypotd)

Securing MySQL is very important and if you're managing a server with MySQL enabled, you should be using this honeypot to trace any suspicious activities on your MySQL server.

[mysql-honeypotd](https://github.com/sjinks/mysql-honeypotd) is a low interaction honeypot written in C.

---

- [DemonHunter](https://github.com/RevengeComing/DemonHunter)

DemonHunter is a low interaction honeypot with an Agent-Master design.

Agents are used to deploy honeypots across various different protocols. Masters receive the attack information.

---

- [phpmyadmin_honeypot](https://github.com/gfoss/phpmyadmin_honeypot)

Honeypot for PHPMyAdmin login panels. Just like django-admin-honeypot for Django based applications.

---

- [HonnyPotter](https://github.com/MartinIngesen/HonnyPotter)

WordPress is a huge part of the internet and if you're someone who uses WordPress to manage your business, blog page or anything else then consider using this honeypot that comes in the form of a WordPress plugin and is available at [https://wordpress.org/plugins/honnypotter/](https://wordpress.org/plugins/honnypotter/)

It logs all failed login-attempts.

---

I hope you enjoyed reading this post and got to know about some of the open source honeypots available for your use.

If you want to connect with me - I'm on [Twitter!](https://twitter.com/ritiksahni22)

Thanks for reading 👋