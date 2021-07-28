---
layout: post
title: "Do you know the types of DNS records?"
color: rgb(23, 71, 82)
permalink: "/dns-records"
excerpt_separator: <!--more-->
author: ritiksahni
tags: [DNS, DNSSEC]
---

<center><img src="/assets/img/posts/dns_records/header.png"></center><br>


You might have heard of DNS (domain name system), but do you know about the basic DNS records that are used to facilitate the entire system of DNS? Let us understand that now!

<!--more-->

# Contents <a name="top">
* [What is DNS?](#what-is)
* [DNS Record Types](#record-types)
* [Is DNS Secure?](#security)
    * [DNSSEC](#dnssec)

---

# What is DNS? <a name="what-is">

DNS stands for Domain Name System. This system translates domain names to IP addresses. Most of the time, we all share and use domain names to access resources over the web. The domain names are just human-readable names we can use to access resources on the web, but for that, our browsers need to know the IP addresses of the servers from where the resources need to be requested.

DNS does the work for us whenever we type in a domain name to access any type of resource, it can be done from a web browser, a command-line utility, or any other method that uses domain names for communicating with a server.

Let's understand DNS record types first and then we will proceed with learning how DNS works on the internet.

# DNS Record Types <a name="record-types">

DNS servers require some important information to configure the domains to align with the servers and for the domain name system to properly function over the internet. The required information is set as "DNS Records" and there are several types of DNS records that we are now going to take a look at.


Here are some of the most common DNS record types:

- **A record (Address Mapping Record)**: This record stores a hostname and the IPv4 address belonging to the hostname.
- **AAAA record (IPv6 address record)**: This record stores a hostname and the IPv6 address belonging to the hostname.
- **CNAME record (Canonical name)**: It can be used to create an alias to another hostname.
- **MX record (Mail Exchanger)**: It can be used to specify details of the SMTP server, if in use.
- **NS record (Nameservers)**: It is used to specify the authoritative nameservers, DNS resolvers usually query the authoritative nameservers to obtain information such as the IP address of the server.
- **CERT record (certificates)**: It can be used to store encryption certificates such as PGP keys.
- **PTR record (reverse-lookup pointer)**: It helps in the resolving of IP address to a domain name, this is required for a reverse DNS lookup.
- **SRV record (Service Location)**: It is used to specify the host and port number of services like VoIP so communication can be established.

These are some basic types of DNS records, but these are not all. In most cases, you'll be using these records.

Now that you know the most common DNS records, it's time to understand the security aspect of the domain name system.

---

# Is DNS secure? 🔒 <a name="security">

DNS in itself is **not secure**. The data is unprotected against attacks like DNS cache poisoning, MiTM. To add a layer of security, we use something known as **DNSSEC**.

## What is DNSSEC? <a name="dnssec">

DNSSEC stands for **Domain Name System Security Extensions**. It is a set of protocols that adds a layer of security to the standard DNS.

DNSSEC ensures integrity and authentication of the DNS data by signing all the DNS records using public-key cryptography.

DNS Zones have a public/private key pair, and the DNS data is signed using the private key, and the key is kept secret with the DNS zone owner. The public key is distributed to the recursive DNS resolvers that is further used to validate the DNS data. In the entire loop of DNS queries, the zone's public key is signed by the parent's private key.

For more information about DNSSEC, refer to the following resources:

- [https://www.cloudflare.com/en-gb/dns/dnssec/how-dnssec-works/](https://www.cloudflare.com/en-gb/dns/dnssec/how-dnssec-works/)
- [https://blogs.akamai.com/2019/06/dnssec-how-it-works-key-considerations.html](https://blogs.akamai.com/2019/06/dnssec-how-it-works-key-considerations.html)

---

I hope you got to know the basic understanding of the most common DNS records that we use. We can't always remember the usage of all the DNS records, and it's completely fine! Sometimes, it's about knowing **where** to find what you need rather than memorizing what you may need in the future, and this blog is for you - feel free to refer to this post whenever you get stuck with DNS and want some help.

If you want to connect with me - I'm on [Twitter!](https://twitter.com/ritiksahni22)

---

Update - I've started my cybersecurity & tech podcast!

**Raw Phish** is available on all of the major podcast streaming platforms. Subscribe to the podcast for audio content 😊

Raw Phish Podcast - [https://anchor.fm/rawphish](https://anchor.fm/rawphish)

I'll see you there 👋