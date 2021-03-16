---
layout: post
title: "DNS Records"
color: rgb(67, 154, 98)
permalink: "/dns-records"
excerpt_separator: <!--more-->
author: ritiksahni
tags: []
---

This blog will teach you about what sort of DNS records developers use to setup websites and emailing services. This blog is aimed at people who want to learn about some of the internals of server deployment activities. 

<!--more-->

# Contents <a name="top">
* [What is DNS?](#what-is)
* [DNS Record Types](#record-types)


---

# What is DNS? <a name="what-is">

DNS stands for Domain Name System. This system translates domain names to IP addresses. Most of the times, we all share and use domain names to access resources over the web, the domain names are just human-readable names we can use to access resources but for that our browsers need to know the IP addresses of the servers from where we are trying to access the resources. 

DNS does the work for us, whenever we type in a domain name in the URL bars of our browsers to just try to send an HTTP request through any means, there is a DNS query sent to fetch the IP address behind the specified domain name.

Let's understand DNS record types first and then we will proceed with learning how DNS works on the internet.

# DNS Record Types <a name="record-types">

DNS servers require some important information to configure the domains to align with the servers and for domain name system to properly function over the internet. The required information is set as "DNS Records" and there are several types of DNS records which we are now going to take a look at.


Here are some of the most common DNS record types:

- **A record (Address Mapping Record)**: This record stores a hostname and the IPv4 address belonging to the hostname.
- **AAAA record (IPv6 address record)**: This record stores a hostname and the IPv6 address belonging to the hostname.
- **CNAME record (Canonical name)**: It can be used to create an alias to another hostname.
- **MX record (Mail Exchanger)**: It can used to specify details of the SMTP server, if in use.
- **NS record (Nameservers)**: It is used to specify the authoritative nameservers, DNS resolvers usually query the authoritative nameservers to obtain information such as the IP address of the server.
- **CERT record (certificates)**: It can be used to store encryption certificates such as PGP keys.
- **PTR record (Reverse-lookup pointer)**: It helps in the resolving of IP address to a domain name, this is required for reverse DNS lookup.
- **SRV record (Service Location)**: It is used to specify the host and port number of services like VoIP so communication can be established.