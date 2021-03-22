---
layout: post
title: "Introduction to Spyse: Internet Assets Registry for Hackers!"
# color: rgb(22, 22, 22)
color: rgb(42,94,168)
permalink: "/intro-to-spyse"
excerpt_separator: <!--more-->
author: ritiksahni
tags: ["Reconnaissance", "Spyse", "Enumeration"]
---

<center><img src="assets/img/posts/intro_spyse/spyse-logo.png"></center>

<br>

Information gathering is an integral part of cybersecurity. We require enumerating our target to know any potential loopholes. Being a cybersecurity enthusiasts we use different services like [Shodan](https://www.shodan.io/), [Censys](https://censys.io/) and perform things like fingerprinting, Google Dorking etc. This blog will make you familiar with another great service which is [Spyse](https://spyse.com/).

<!--more-->

# Contents <a name="top">
* [Introduction](#introduction)
* [Who is it for?](#who)
* [Features](#features)
* [Pricing](#pricing)
* [More from Spyse](#more)

# Introduction <a name="introduction">

Spyse is an internet assets registry, Spyse collects information from millions of different digital assets or servers from around the globe and give us access to the data which can be used for any type of enumeration activities, surveys, monitoring etc.


They also provide an API so you have an option to do any monitoring, data gathering activities and get everything done on your own machines with the help of API calls rather than relying on the web interface! This is very handy in cases of automation of information gathering. Many famous open source tools and frameworks use Spyse as an option to gather information, all of it is possible through the API functionalities provided by Spyse.

![spyse-tools](assets/img/posts/intro_spyse/spyse-tools-api.png)

We can see that tools like Findomain, Subfinder, Spiderfoot, OWASP Amass have integrated Spyse's API.

# Who is it for? <a name="who">

Any cybersecurity professional or anyone interested learning more about the internet! Spyse has great features you are going to see further in this blog.
There are a lot of filters to use and narrow down the scope of data and the way it's presented to us.


# Features <a name="features">

Let's dive into the technical part of the blog. Spyse has many features and filters to do our enumeration and narrow down the results based on our needs. It offers tools for tasks such as lookups for Domains, ASN, IP addresses, SSL certificates, MX recordss, WHOIS data.

There are more unique features such as reconnaissance using AdSense IDs, and CVE search.


You can visit [https://spyse.com/](https://spyse.com/) and you'll be presented with a simple search bar to query any domain, IP, Organization etc.

Before you start playing around, [create an account](https://spyse.com/user/registration?subscription_id=5) on Spyse and then log in using your credentials.

![spyse-login](assets/img/posts/intro_spyse/spyse-login.png)

The login page looks like this, navigation to the homepage gives us a basic search functionality and underneath the search bar we have a 3 options which are "Advanced Search", "Bulk Search", "API".

![menu](assets/img/posts/intro_spyse/menu.png)

- **Advanced Search**: It takes to a page where we can apply different filters (upto 10) and search for our desired results based upon domain names, IP hosts, SSL certificates, Autonomous System Numbers, Organization details, CVE ID search, Technologies.

![cms-made-simple-search](assets/img/posts/intro_spyse/cms-advanced-search.png)

You can see that I applied a "Technology" filter with name "CMS Made Simple" which is a content-management system and Spyse served me about 3200 results of assets which use the specified CMS. We can apply more filters to narrow down the scope and gain results of more specific organizations.

You can play around with this feature and build as many custom queries as you want, if you're collaborating with someone for the reconnaissance then you can also export the results in CSV or JSON format to share or simple copy the link in your URL bar and share it with any one you want to show the results you fetched.

- **Bulk Search**: With this feature, we can lookup for multiple IP addresses or domain names together at once. It is only available for PRO subscribers.

![bulk-search](assets/img/posts/intro_spyse/bulk-search.png)

You can see that I put in 4 different domain names, Spyse queried these domains from its registry and presented some information about it.

![bulk-search-data](assets/img/posts/intro_spyse/bulk-search-data.png)

The initial set of data consists of HTTP Site Title, Alexa rank, DNS A records, etc. There is a "Columns" button on the top right side which can be used to add more information sets to the page (e.g. IP Address, DNS records, Technologies)

- **API**: Spyse provides a very cool application programming interface which is used by many open source tools from several developers, organizations.

Documentation for the API can be found here: [https://spyse-dev.readme.io/reference/quick-start](https://spyse-dev.readme.io/reference/quick-start)

![api-spyse](assets/img/posts/intro_spyse/api-spyse.png)


We can see that it provides us an interface to simply input the data we have and it gives us the code for sending the API request to the dedicated endpoints. There is cURL command, NodeJS code, Ruby, Javascript, Python script built out for you to simply run in your systems. You can edit the code based up on your preferences or build out your own API queries with the required parameters specified in the documentation for better use of the API feature.


# Pricing <a name="pricing">

We will now see the subscription/pricing levels of using Spyse.

In all the subscription plans you have the option to pay for a month or for the whole year. In yearly subscription, you get a 10% off the price as compared to monthly charges.

![pricing](assets/img/posts/intro_spyse/spyse_pricing.png)

There is a total of 4 different plans with different perks included in them.

**Guest Plan**   
Free of charge, it has basic or common search feature and access to 51 different filters in Advanced search option. A maximum of 2 filters can be applied at a time. 

In this free plan, search results are limited but we can agree that any data can be helpful at any stage of reconnaissance, it depends up on the purpose of use if Spyse's free plan will be sufficient for you or not.

For testing purposes, it is highly recommended to check out this free tier and get familiarized with the interface.

You DO NOT get the download/export data feature, API access, bulk search feature with this tier.


---

**Standard Plan**

This tier offers access to bulk search, export data (up to 10 downloads per month) and access to API for up to 1000 requests per month.

It allows us to use up to 138 different filters in Advanced Search. It's good for people with need of more reliable data and access to advanced features.

The monthly cost of this tier is $40 per month as of now.

---

**PRO Plan**


This tier is the highest tier available for most of the non-commercial users. It offers up to 160 different Advanced Search filters, access to API with allowance of 50,000 requests per month. Pro subscribers also get 1-hour of onboarding call with a technical team expert from Spyse to get more information about Spyse and getting help with the different things they offer.

The monthly cost of this tier is $200 per month as of now.

---

**Business Plan**

This plan is exclusive to business and enterprise customers, if your business thinks that Spyse can be of any use, you can email [sales@spyse.com](mailto:sales@spyse.com). The pricing and specifics of this plan is flexible!

---

You can visit [https://spyse.com/pricing](https://spyse.com/pricing) for more in-depth information.

# More from Spyse <a name="more">

Spyse has done a few more great things, one of my favorites is the "Technologies" page which can be found here: [https://spyse.com/explore/technologies](https://spyse.com/explore/technologies)

![tech](assets/img/posts/intro_spyse/spyse-tech.png)

We can see that there's a whole page with the list of technologies they detect across the internet! We can just choose any technology here and it'll give us some of the domain names, IP addresses it caught using the same technology.

Let's say you have an exploit for Adobe Experience Manager CMS or Jira issue tracking software, you can go on this page and choose the technology and get yourself some targets to test the vulnerability. Make sure to test targets with appropriate authority and permission to test them, not testing ethically 
can lead you to legal consequences.


Spyse regularly tweets about some CVEs, search presets for the community! Here's an example:

<center>
{% twitter https://twitter.com/SpyseHQ/status/1372115763583127556 %}
</center>


They have mentioned about GravCMS which has some critical CVEs on it, they've given a Spyse URL which is the link to discover targets using GravCMS through the technologies feature.

https://spyse.com/target/technology/Grav

---

Spyse has a page for search presets which has already built advanced search queries ready for use. Although there isn't much stuff available there but I hope they soon add more presets, and interesting search queries.

The presets page can be found here: [https://spyse.com/explore/presets](https://spyse.com/explore/presets)

![Search Presets Page](assets/img/posts/intro_spyse/presets.png)

---

I hope you liked this blog and got familiarized with Spyse! I surely like the features and especially "Advanced Search", if you're someone who wants to level up their recon game, you should definitely look into adding Spyse into your arsenal. Do you like it? Let me know on my Twitter!

**THANKS FOR READING! You're awesome ;)**

[Back to Top](#top)