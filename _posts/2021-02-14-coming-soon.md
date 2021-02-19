---
layout: post
title: "Deep Dive into Content Security Policies"
permalink: "/content-security-policy"
color: rgb(122, 50, 101)
excerpt_separator: <!--more-->
author: ritiksahni
tags: [CSP, Bug Bounty, Web Security, Web, HTTP, XSS]
---

<!-- ![csp_banner](assets/img/posts/csp/csp_banner.png) -->

This blog will teach you how content security policies work and prevent attacks such as XSS, clickjacking. We will also cover some scenarios with CSP misconfigurations to understand how an attacker can leverage it to his own benefit and ways to prevent that. After reading this blog, you should get a better understanding of how CSP works and you will be able to analyze CSP headers and detect misconfigurations in the wild.

<!--more-->

## Contents <a name="top">
* [What is CSP?](#intro)
    * [Implementations](#implementations)
* [How to use CSP?](#how-csp)
* [CSP Directives](#csp-directives)
* [Source List](#csp-directives)
* [Defining Policies](#defining-policies)
* [Real World Examples](#rw-examples)
* [CSP Misconfigurations](#misconfig)
* [Resources](#resources)

---

## What is CSP? <a name="intro">

CSP (Content Security Policy) is used by developers to enforce resource sharing rules and is a security standard that can help in the prevention of client-side attacks such as cross-site scripting (XSS), iFrame injection (clickjacking).


#### Implementations <a name="implementations">

There are a couple of headers that can be used to enforce content security policies. The most common one is "Content-Security-Policy" while the others are deprecated. The headers are as follows:

- __Content-Security-Policy__: Most commonly used header for implementing CSP. It is supported by browsers like Google Chrome, Firefox, Microsoft Edge, Safari, etc.

- __X-WebKit-CSP__: It is **deprecated** and was introduced into Google Chrome and Safari in 2011.

- __X-Content-Security-Policy__: It is **deprecated** and was introduced in Gecko (a browser engine) based browsers such as Firefox, SeaMonkey, Lunascape.

We currently use the CSP version 3, you can see the changes from the previous version of CSP here: [https://w3c.github.io/webappsec-csp/#changes-from-level-2](https://w3c.github.io/webappsec-csp/#changes-from-level-2).

---

## How to use CSP? <a name="how-csp">

We can specify content security policies by adding the following HTTP header in the response:

```
Content-Security-Policy: DIRECTIVE-NAME 'SOURCE'
```

The header requires **directives** which are the actual entries that tells the browsers what sort of resource sharing structure to enforce.

Directives are simply the values using which we can control the policy structure. Let's understand some common CSP directives here:

## CSP Directives <a name="csp-directives">


- **default-src**: This directive specifies the default source of resources. In case other directives are not specified for the sharing of javascript code, images, media, fonts then the browser uses the source specified in default-src to load all of those resources. This acts like a __fallback__ from the other directives.  
<br>

- **script-src**: This directive specifies the trusted source from where to load JS scripts. This could be given the value of the server itself if the scripts are stored locally or sometimes the hostname of CDN server from where the scripts are supposed to be loaded. If script-src is set to cdn.example.com then it cannot load javascript from attacker.com and attacker.com isn't specified in the policy and hence the browser will not load any scripts from hosts not present in the policy.  
<br>

- **img-src**: It works similar to script-src but this directive specifies the trusted source for images rather than scripts. The browser won't load images from any source not specified in the policy.  
<br>

- **connect-src**: This directive is used to tell the browser the trusted endpoints or hosts to which the website can communicate with. If the website wants to make an HTTP request to api.example.com then the policy would look like "connect-src 'api.example.com'" and then it won't be able to send requests to any other third-party websites. This can help prevent external service interaction.  
<br>

- **style-src**: This directive is used to specify the trusted sources to load the stylesheet or the CSS files from. We can specify hosts like 'fonts.googleapis.com' if the website uses fonts from Google Fonts. This could help in the prevention of attacks such as CSS injection.  
<br>

- **worker-src**: This directive is used to specify sources that are allowed to run web workers in the background. Web workers allow an application to run javascript code in background threads. You can have more information about web workers here: [https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Using_web_workers](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Using_web_workers)  
<br>

- **report-uri**: This directive is depreciated but is still found in many web applications. It has a host specified in its value where a JSON report is sent with the data of any violations of CSP within an application. The data is sent through HTTP POST request to the server specified with this directive.  
<br>

- **form-action**: This directive can be used to specify hosts where HTML form data can be submitted. The browser won't send data to any third-party host if it is not explicitly specified with this directive. 
<br>

- **media-src**: This directive can be used to specify trusted sources from where media files like audios and videos can be requested.  
<br>

- **prefetch-src**: This directive can be used to specify trusted sources for requesting __prefetch__ via HTML tags like `<link rel="prefetch">`  
<br>

- **frame-ancestors**: This directive can be used to specify which URLs can frame the current webpage. This can be used as an alternative to            <br>`X-Frame-Options: deny` header. We can limit the hosts which can frame the webpage using this directive.  
<br>

- **base-uri**: This directive can be used to specify the trusted sources which can be used inside the `<base>` tag in `src` attribute.  
<br>

- **child-src**: This directive can be used to specify the hosts which can be used in iFrames inside the current webpage.  
<br>

- **frame-src**: This is the same as child-src. It was deprecated from CSP2 in favor of `child-src` and then un-deprecated from CSP3. The functionality is same as child-src and developers are endorsed to use this instead of child-src.  
<br>

---

## Source List <a name="source-list">

We've discussed the directives which can be used to specify different rules but they need the values with them so it becomes a proper policy that will tell the browser what to do, which resources to give access to, and how.

Value | Description
---        |       --- 
 \*         |  It is the wildcard and can be used to allow everything.
 'self'     | It is used to tell the directive to just allow from the same origin and no other resource. Hence the name 'self'.
 'none'     | It is used to tell the directive to not allow __any__ origin. It is commonly used to prevent the website from loading any type of resource like script or images etc.
 'data:'    | It is used to tell the directive to allow data:// scheme, it can be used to allow/disallow base64 encoded images and code.
 'domain.com' | It is a value which can be specified with the directive so that the directive allows the specific domain name for resource sharing and other tasks.
 '*.domain.com' | This value can be used if we wanna allow any subdomain of `domain.com` to be able to share resources with our website.
 'https:'  | This can be used to make sure that the directive allows only the domains with HTTPS in use. This can help prevent resource sharing over insecure channels.
 'unsafe-inline' | This value can be used to allow the website to use inline elements such as style, scripts.
 'unsafe-eval' | This allows the use of `eval`.
 'sha256-HASH' | This can be used to make sure that only the resources with the specified or whitelisted hashes are being loaded and executed.
 'nonce-VALUE' | This allows scripts, CSS to be executed only if they have the nonce attribute and it matches with the nonce in the CSP header. It is recommended that the nonce should be random, unguessable (for security reasons).

---

## Definition Examples <a name="defining-policies">

We will now study some examples of CSP headers.

- **Allowing scripts and images from the same origin server itself.**

```
Content-Security-Policy: script-src 'self' img-src 'self'
```

- **Allowing base64 encoded images from a CDN server.**

```
Content-Security-Policy: "img-src data: cdn.example.com"
```

- **Allowing a subdomain to be framed in the current webpage**

```
Content-Security-Policy: "frame-src sub.example.com"
```

- **Default Source policy with subdomains, data scheme**

```
Content-Security-Policy: "default-src 'self' data: cdn.example.com server.example.com"
```

- **Allowing Google Fonts to share its resources**

```
Content-Security-Policy: "font-src fonts.googleapis.com"
```

You can add CSP headers by editing the configuration files of your web server or adding the following tag inside the head tag of your HTML code: 
```html
<!-- Example to add default-src 'self' as the directive -->
<meta http-equiv="Content-Security-Policy" content="default-src 'self'">
```

I hope you've understood the policy definition process through the given examples.

---

## Real world examples <a name="rw-examples">

We will now see some examples of how real-world web applications use content security policies. Analyzing CSP headers also gives names of subdomains, CDN servers which can help do further recon during bug bounty, pentesting.

For checking CSPs you just have to send a request to the website and analyze the response, there must be a `Content-Security-Policy` header in the response if the website uses it.


- **github.com**

```
Content-Security-Policy: default-src 'none'; base-uri 'self'; block-all-mixed-content; connect-src 'self' uploads.github.com www.githubstatus.com collector.githubapp.com api.github.com github-cloud.s3.amazonaws.com github-production-repository-file-5c1aeb.s3.amazonaws.com github-production-upload-manifest-file-7fdce7.s3.amazonaws.com github-production-user-asset-6210df.s3.amazonaws.com cdn.optimizely.com logx.optimizely.com/v1/events wss://alive.github.com github.githubassets.com; font-src github.githubassets.com; form-action 'self' github.com gist.github.com; frame-ancestors 'none'; frame-src render.githubusercontent.com; img-src 'self' data: github.githubassets.com identicons.github.com collector.githubapp.com github-cloud.s3.amazonaws.com user-images.githubusercontent.com/ *.githubusercontent.com customer-stories-feed.github.com spotlights-feed.github.com; manifest-src 'self'; media-src github.githubassets.com; script-src github.githubassets.com; style-src 'unsafe-inline' github.githubassets.com; worker-src github.com/socket-worker-5029ae85.js gist.github.com/socket-worker-5029ae85.js
```

We can see that GitHub uses CSP to define sources for frames, base tags, form actions, workers etc. We can see S3 buckets, WebSockets, CDN servers. Such information is crucial during recon.

- **linkedin.com**

```
Content-Security-Policy: default-src 'none'; base-uri 'self'; form-action 'self'; connect-src 'self' wss: blob: static-src.linkedin.com https://www.linkedin.com cdn.lynda.com s2.lynda.com video-uploads-prod.s3.amazonaws.com video-uploads-prod.s3-accelerate.amazonaws.com https://media-src.linkedin.com/media/ https://dpm.demdex.net/id lnkd.demdex.net *.licdn.com realtime.www.linkedin.com graph.microsoft.com dmsuploads.www.linkedin.com https://linkedin.sc.omtrdc.net/b/ss/ www.google-analytics.com https://go.trouter.skype.com/v4/ platform.linkedin.com platform-akam.linkedin.com platform-ecst.linkedin.com platform-azur.linkedin.com; img-src data: blob: *; font-src data: *; frame-src 'self' blob: *.doubleclick.net www.slideshare.net radar.cedexis.com media-lcdn.licdn.com m.c.lcdn.licdn.com cdn.embedly.com https://www.linkedin.com lichat.azurewebsites.net www.youtube.com www.youtube-nocookie.com www.facebook.com player.vimeo.com embed.ted.com livestream.com embed.gettyimages.com w.soundcloud.com www.lynda.com *.megaphone.fm msit.powerbi.com app.powerbi.com linkedin.github.io lnkd.demdex.net linkedin.cdn.qualaroo.com platform.linkedin.com platform-akam.linkedin.com platform-ecst.linkedin.com platform-azur.linkedin.com static.licdn.com static-exp1.licdn.com static-exp2.licdn.com static-exp3.licdn.com media.licdn.com media-exp1.licdn.com media-exp2.licdn.com media-exp3.licdn.com; child-src 'self' blob: *.doubleclick.net www.slideshare.net radar.cedexis.com; style-src 'unsafe-inline' s.c.lnkd.licdn.com static-fstl.licdn.com static-src.linkedin.com static-lcdn.licdn.com s.c.lcdn.licdn.com https://www.linkedin.com/sc/ https://www.linkedin.com/scds/ https://qprod.www.linkedin.com/sc/ static.licdn.com static-exp1.licdn.com static-exp2.licdn.com static-exp3.licdn.com; script-src 'report-sample' 'sha256-6gLjSWp3GRKZCUFvRX5aGHtECD1wVRgJOJp7r0ZQjV0=' 'unsafe-inline' s.c.lnkd.licdn.com static-fstl.licdn.com static-src.linkedin.com https://www.linkedin.com/voyager/service-worker-push.js static-lcdn.licdn.com s.c.lcdn.licdn.com https://www.linkedin.com/sc/ https://www.linkedin.com/scds/ https://qprod.www.linkedin.com/sc/ https://www.linkedin.com/sw.js https://www.linkedin.com/voyager/abp-detection.js https://snap.licdn.com/li.lms-analytics/ https://platform.linkedin.com/js/analytics.js https://platform-akam.linkedin.com/js/analytics.js https://platform-ecst.linkedin.com/js/analytics.js https://platform-azur.linkedin.com/js/analytics.js https://platform.linkedin.com/litms/utag/ https://platform-akam.linkedin.com/litms/utag/ https://platform-ecst.linkedin.com/litms/utag/ https://platform-azur.linkedin.com/litms/utag/ https://platform.linkedin.com/litms/vendor/ https://platform-akam.linkedin.com/litms/vendor/ https://platform-ecst.linkedin.com/litms/vendor/ https://platform-azur.linkedin.com/litms/vendor/ static.licdn.com static-exp1.licdn.com static-exp2.licdn.com static-exp3.licdn.com; media-src blob: *; manifest-src 'self'; frame-ancestors 'self'
```

Same as GitHub, there are many CDNs, subdomains and we can see that LinkedIn also uses SHA256 for loading scripts which is considered a really secure way.

- **Twitter**

```
content-security-policy: connect-src 'self' blob: https://*.giphy.com https://*.pscp.tv https://*.video.pscp.tv https://*.twimg.com https://api.twitter.com https://api-stream.twitter.com https://ads-api.twitter.com https://caps.twitter.com https://media.riffsy.com https://pay.twitter.com https://sentry.io https://ton.twitter.com https://twitter.com https://upload.twitter.com https://www.google-analytics.com https://app.link https://api2.branch.io https://bnc.lt https://vmap.snappytv.com https://vmapstage.snappytv.com https://vmaprel.snappytv.com https://vmap.grabyo.com https://dhdsnappytv-vh.akamaihd.net https://pdhdsnappytv-vh.akamaihd.net https://mdhdsnappytv-vh.akamaihd.net https://mdhdsnappytv-vh.akamaihd.net https://mpdhdsnappytv-vh.akamaihd.net https://mmdhdsnappytv-vh.akamaihd.net https://mdhdsnappytv-vh.akamaihd.net https://mpdhdsnappytv-vh.akamaihd.net https://mmdhdsnappytv-vh.akamaihd.net https://dwo3ckksxlb0v.cloudfront.net ; default-src 'self'; form-action 'self' https://twitter.com https://*.twitter.com; font-src 'self' https://*.twimg.com; frame-src 'self' https://twitter.com https://mobile.twitter.com https://pay.twitter.com https://cards-frame.twitter.com ; img-src 'self' blob: data: https://*.cdn.twitter.com https://ton.twitter.com https://*.twimg.com https://analytics.twitter.com https://cm.g.doubleclick.net https://www.google-analytics.com https://www.periscope.tv https://www.pscp.tv https://media.riffsy.com https://*.giphy.com https://*.pscp.tv https://*.periscope.tv https://prod-periscope-profile.s3-us-west-2.amazonaws.com https://platform-lookaside.fbsbx.com https://scontent.xx.fbcdn.net https://*.googleusercontent.com; manifest-src 'self'; media-src 'self' blob: https://twitter.com https://*.twimg.com https://*.vine.co https://*.pscp.tv https://*.video.pscp.tv https://*.giphy.com https://media.riffsy.com https://dhdsnappytv-vh.akamaihd.net https://pdhdsnappytv-vh.akamaihd.net https://mdhdsnappytv-vh.akamaihd.net https://mdhdsnappytv-vh.akamaihd.net https://mpdhdsnappytv-vh.akamaihd.net https://mmdhdsnappytv-vh.akamaihd.net https://mdhdsnappytv-vh.akamaihd.net https://mpdhdsnappytv-vh.akamaihd.net https://mmdhdsnappytv-vh.akamaihd.net https://dwo3ckksxlb0v.cloudfront.net; object-src 'none'; script-src 'self' 'unsafe-inline' https://*.twimg.com   https://www.google-analytics.com https://twitter.com https://app.link  'nonce-NmEwZDNhODAtYzgyNS00ZTQzLTk4NGEtODM5NjliZmU1NjRi'; style-src 'self' 'unsafe-inline' https://*.twimg.com; worker-src 'self' blob:; report-uri https://twitter.com/i/csp_report?a=O5RXE%3D%3D%3D&ro=false
```

Twitter connects to services like Giphy, Periscope, some API servers, Google Analytics. In the end, there's also a report-uri directive with the endpoint which receives CSP violation reports.

---

## CSP Misconfigurations <a name="misconfig">

We've understood how CSP works and how applications have implemented it. Let us now understand how we can abuse CSP misconfigurations as a hacker.

There could be many scenarios where we can try to exploit XSS, clickjacking if the CSP has been misconfigured on the target domain.

**Scenario 1 - Unsafe Inline**


Let's assume we have a target that has the following policy configured:

```css
/* Exploiting unsafe inline/eval */
Content-Security-Policy: default-src 'self' script-src cdn.example.com cdn2.example.com 'unsafe-inline'
```

Unsafe inline makes the browser allow inline scripts.

We can use the following payloads to exploit this:

```js
<script>alert("XSS")</script> 
```
It's a simple payload that gives an alert over the window, as unsafe-inline is allowed this inline code will get executed.

**Scenario 2 - Wildcards**

Let's assume we have a target that has the following policy configured:

```css
/* Exploiting wildcards */
Content-Security-Policy: default-src 'self' script-src *.amazonaws.com
```

Obviously, the developer wants the website to be able to load scripts from an S3 bucket and uses a wildcard over the amazonaws.com domain name. In this case, inline XSS payloads aren't gonna work but now know that it trusts scripts that come from amazonaws.com, we can create our own AWS S3 bucket and host a javascript file with our malicious code. If the website doesn't have any security mechanisms like input sanitizing and filtering we can just try to use a payload like this...

Another similar scenario would be if the website trusts domains like `cdnjs.cloudflare.com`. In that case, we can load any library from that public service. You can just go to [https://cdnjs.com/](https://cdnjs.com/) and choose a library and add the URL to the script tag's src attribute. It'll be a sort of hijack situation.

```js
<script src="https://attacker-bucket.amazonaws.com/script.js"></src>
```

The browser will allow this because CSP tells the browser to trust any subdomain of amazonaws.com for loading scripts and we just have that!

**Scenario 3 - Data Scheme**

Let's assume we have a target that has the following policy configured:

```css
Content-Security-Policy: default-src 'self' script-src data:
```

This allows the use of data scheme. Inline script like `<script>alert("XSS")</script>` could be blocked by the browser but we have the allowance of using data scheme so we use a payload like the following one:

```js
<script src="data:;base64,YWxlcnQoZG9jdW1lbnQuY29va2llKQ=="></script>
```

This contains the base64 encoded string `alert(document.cookie)` and this will be allowed by the browser because we used data scheme and then we should be getting an alert popup with the cookies of the current session if the application is vulnerable.

---

There could be many other scenarios and one huge takeaway from all of this is don't blindly put in all sorts of XSS payloads on an application, enumerating CSP and analyze those. Look for ways you can exploit misconfiguration. Look for domains trusted by the target application which could be controlled by you (we saw that in the wildcard example). 

## Resources <a name="resources">

Here are some resources which can help you with any work related to content security policies.


[https://report-uri.com/home/generate](https://report-uri.com/home/generate) - Creating CSPs easily.  
[https://csp-evaluator.withgoogle.com/](https://csp-evaluator.withgoogle.com/) - Analyzing the security of the policies.  
[https://cspvalidator.org/](https://cspvalidator.org/) - Analyzing CSPs by entering the target name.  
[https://github.com/bhaveshk90/Content-Security-Policy-CSP-Bypass-Techniques](https://github.com/bhaveshk90/Content-Security-Policy-CSP-Bypass-Techniques) - Understanding more CSP misconfigurations.  


---

**I hope you enjoyed this article and gained some valuable knowledge about content security policies and securing those. Feel free to contact me for any suggestions, feedbacks and I would really appreciate those.** [Contact Me](/contact)

<div style="width:60%;height:0;padding-bottom:30%;position:relative;"><iframe src="https://giphy.com/embed/1CTRUV2uFX27h4pzul" width="50%" height="50%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div><p><a href="https://giphy.com/gifs/thank-you-thanks-thankyou-1CTRUV2uFX27h4pzul"></a></p>

You can also [Buy Me A Coffee](http://buymeacoffee.com/ritiksahni) to support this blog page!

[Back to Top](#top)