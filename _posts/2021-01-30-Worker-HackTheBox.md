---
layout: post
title: "Worker - HackTheBox"
permalink: "/worker-hackthebox"
color: rgb(60, 45, 179)
excerpt_separator: <!--more-->
author: ritiksahni
tags: [HackTheBox, Azure, Windows, DevOps, VCS, SVN]
---

<center><img src="assets/img/posts/worker-htb/worker_header.png"></center><br>

Worker is a Windows box created by [ekenas](https://www.hackthebox.eu/home/users/profile/222808). It takes us through gaining access to Azure DevOps service from hardcoded credentials in a Subversion repository which is an open source version control system and using those credentials to login and uploading a shell to the present repositories to gain low privileged access and further getting user system login credentials from a file in the machine, to get root flag we have to use Azure Pipelines to execute Powershell commands.

<!--more-->

## Contents <a name="top">
* [Port Scanning](#port-scanning)
* [HTTP (Port 80)](#port-80)
* [Subversion](#svn-port)
    * [Understanding Version Control System](#understanding-vcs)
* [Privilege Escalation to Robisl](#privesc-robisl)
* [Privilege Escalation to Administrator](#privesc-admin)
    * [Understanding DevOps Pipelines](#understanding-pipelines)

---

## Port Scanning <a name="port-scanning">

```
Nmap scan report for 10.10.10.203
Host is up (0.36s latency).

PORT     STATE SERVICE  VERSION
80/tcp   open  http     Microsoft IIS httpd 10.0
| http-methods:
|_  Potentially risky methods: TRACE
|_http-server-header: Microsoft-IIS/10.0
|_http-title: IIS Windows Server
3690/tcp open  svnserve Subversion
5985/tcp open  http     Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
|_http-server-header: Microsoft-HTTPAPI/2.0
|_http-title: Not Found
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Sun Jan 24 13:47:36 2021 -- 1 IP address (1 host up) scanned in 11.45 seconds
```

We can observe that 3 ports are open:

80 - HTTP (Microsoft IIS httpd 10.0)  
3690 - Subversion  
5985 - HTTP (Microsoft HTTPAPI)  


SVN is very interesting here and we can use an nmap script 'svn-brute' to enumerate more of this service.
Run command: `nmap --script=svn-brute --script-args svn-brute.repo=/svn/ -p 3690 -oA nmap/svn-brute 10.10.10.203`
```
Nmap scan report for 10.10.10.203
Host is up (0.32s latency).

PORT     STATE SERVICE
3690/tcp open  svn
| svn-brute:
|_  Anonymous SVN detected, no authentication needed

# Nmap done at Sun Jan 24 13:53:07 2021 -- 1 IP address (1 host up) scanned in 1.81 seconds
```

There is no authentication needed for accessing the SVN repo!

---

## HTTP (Port 80) <a name="port-80">

Visiting http://10.10.10.203 we get the default IIS webpage

![default-iis](assets/img/posts/worker-htb/iis_port80.png)

There's nothing interesting here and we have to proceed looking for things in port 3690 (Subversion) where no authentication is required.

---

## Subversion (Port 3690) <a name="svn-port">

Subversion is an open source version control system by Apache also known as "SVN". Version control systems are used by developers to manage their projects and source code over time efficiently and it is also collaboration friendly. 

For enumerating this port, we can use `svn` command, there are many options available and you can test things out yourself with it but in this case there is an SVN repository which we can dump using `svn checkout svn://10.10.10.203`. Note that we specified svn:// protocol here so we need not specify the port 3690 as it's the default port and specifying the svn:// protocol here is just enough to do the task.

![svn-checkout](assets/img/posts/worker-htb/svn-dump-revision5.png)

It dumps the source code of `dimension.worker.htb`, we will first proceed with adding the names to `/etc/hosts`.

---

#### Understanding Version Control System <a name="understanding-vcs">

There are several famous version control systems such as Git, Mercurial, Subversion, Perforce etc.
They are basically software utilities used to manage versions of projects, source codes. They are mostly used by developer teams and people collaborating. VCS provides a simple way to create different versions of a software and release, roll-back to specific versions and do the needful tasks.

---

Visiting dimension.worker.htb in a browser:

![dimension](assets/img/posts/worker-htb/dimension-homepage.png)

Taking a look at the dumped repository, it is the source code of this website running at `http://dimension.worker.htb`.
There is another interesting thing to look for, it also dumped a text file named `moved.txt`.


File contents of moved.txt:

```
This repository has been migrated and will no longer be maintaned here.
You can find the latest version at: http://devops.worker.htb

// The Worker team :)
```

This indicates that there is another virtual host which is `devops.worker.htb` and we now need to add it to our hosts file in order to get access to the specified repository.

After adding it to /etc/hosts we should now be able to access `http://devops.worker.htb` in our browsers.

We see that this requires authentication (HTTP Basic Auth) and we don't have its credentials yet.

![basic](assets/img/posts/worker-htb/basic-auth-devops.png)

We move back to what we currectly have, we noticed that the SVN repository we checked out was revision 5. We can take a look at previous revisions to see what changes had been gradually made with the SVN repository.

After taking a look at each revision, I found that revision 2 has a file `deploy.ps1` which has the following file contents:

```powershell
$user = "nathen"
$plain = "wendel98"
$pwd = ($plain | ConvertTo-SecureString)
$Credential = New-Object System.Management.Automation.PSCredential $user, $pwd
$args = "Copy-Site.ps1"
Start-Process powershell.exe -Credential $Credential -ArgumentList ("-file $args")
```

Bingo! We get hardcoded credentials! The powershell script simple starts the process `powershell.exe` using `Start-Process` cmdlet and supply it the user credentials which had been defined in the variables.


For checking out revision 2, I used the following command:

```bash
svn checkout svn://10.10.10.203 -r 2
```

Now, we can use the obtained credentials to login to `http://devops.worker.htb`.

![azure-devops](assets/img/posts/worker-htb/azure-devops-homepage.png)

We get this page and it clearly is running [Azure Devops Services](https://azure.microsoft.com/en-in/services/devops/). There is a project here with the name `SmartHotel360`, clicking on it we get some documentation about it. Nothing interesting in the documentation.

We can click on `Repos` to take a look at repository contents.

![repo-files](assets/img/posts/worker-htb/smart-hotel.png)

On the bar on top we have a small drop down menu where we can switch repositories in this project.

![repo-bar](assets/img/posts/worker-htb/devops-repos.png)

Every one of these repositories contains web source code and can by accessed by using repository name as subdomain. We can see dimension repository here, that contains the live source code of the website we visited a while ago (http://dimension.worker.htb)

We now have access to the live repositories of the subdomains on the server, we can try to upload a reverse shell and try to access it in another browser tab to execute it.

I used the reverse shell by borjmz ([https://github.com/borjmz/aspx-reverse-shell](https://github.com/borjmz/aspx-reverse-shell)) for this task.


For uploading it, go to any repository e.g. spectral and click on "New" and then proceed adding the file contents of shell.aspx and commit the changes, there is a small issue here... We can't commit the file addition to the master branch directly but we can create a new branch and create a "Pull Request". As soon as that is done, we can see the merging policies on the right side.

It won't allow us to merge the pull request without an approval of the reviewer (we can give it ourselves), all comments resolved, and without associating a work item (such as a task).

For that we need to create a new work item and for that go to Boards > Work Item > New and then fill in some details and create it. We can now click on the small "+" icon on our pull request page to associate the freshly created work item and all 3 policies should now have green check.

**What are work items?**

In Azure DevOps, we can use work items to manage different tasks, bugs and other typical things which occur in the whole development process, it helps developers to track everything which is going on with the project. In this case, we had to associate the Pull Request with a **work item** to successfully merge it and developers may implement the same policy to avoid unnecessary pull requests which are submitted without having a task assigned for it.

---

We satisfy the policies by associating a work item, approving project and the 3rd check mark should already have a green check as there are no comments in the PR and hence no resolution is required.

![policies](assets/img/posts/worker-htb/merge-policies.png)

We can now successfully merge the pull request.

![merge-complete](assets/img/posts/worker-htb/merge-complete.png)

Now going back to repository contents we can see a new file `shell.aspx` which we added. Start a listener on the port you specified in your reverse shell file and access `http://spectral.worker.htb/shell.aspx`. We finally get a reverse shell!

![reverse_shell](assets/img/posts/worker-htb/reverse_shell.png)

---

## Privilege Escalation to Robisl <a name="privesc-robisl">

We have a low-privilege shell and now our aim is to escalate our privileges to user level. Checking C:\Users we can see that other than Administrator there is a user named "robisl"

I used [WinPEAS](https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite/tree/master/winPEAS) for enumeration and found that there is another drive in the machine which was W:\

However, I wasn't able to use `cd` to go into W:\ but I was able to use `dir` to list all the contents of that drive.

![w-drive](assets/img/posts/worker-htb/dir_w.png)

Looking into these directories I found an interesting file `passwd` which is located at `W:\svnrepos\www\passwd` to be precise. It contains many user/password entries.

File contents of passwd:

```
### This file is an example password file for svnserve.
### Its format is similar to that of svnserve.conf. As shown in the
### example below it contains one section labelled [users].
### The name and password for each user follow, one account per line.

[users]
nathen = wendel98
nichin = fqerfqerf
nichin = asifhiefh
noahip = player
nuahip = wkjdnw
oakhol = bxwdjhcue
owehol = supersecret
paihol = painfulcode
parhol = gitcommit
pathop = iliketomoveit
pauhor = nowayjose
payhos = icanjive
perhou = elvisisalive
peyhou = ineedvacation
phihou = pokemon
quehub = pickme
quihud = kindasecure
rachul = guesswho
raehun = idontknow
ramhun = thisis
ranhut = getting
rebhyd = rediculous
reeinc = iagree
reeing = tosomepoint
reiing = isthisenough
renipr = dummy
rhiire = users
riairv = canyou
ricisa = seewhich
robish = onesare
robisl = wolves11
robive = andwhich
ronkay = onesare
rubkei = the
rupkel = sheeps
ryakel = imtired
sabken = drjones
samken = aqua
sapket = hamburger
sarkil = friday
```

As we know that there is a user `robisl` in the system, we can use the password from `W:\svnrepos\www\passwd` to log in as `robisl` in the machine using tools like [evil-winrm](https://github.com/Hackplayers/evil-winrm).

The password of robisl is `wolves11`.

![evil-winrm](assets/img/posts/worker-htb/robisl_evilwinrm.png)

We got the user shell!

---

## Privilege Escalation to Administrator <a name="privesc-admin">

We have successfully got user account access, now it's time to gain Administrator access... After going back and forth through the machine with access as `robisl` didn't help. In this case, what we need to do is use the same user credentials we got in `W:\svnrepos\www\passwd` to login to the Azure DevOps instance.

We now get access to Azure DevOps services as robisl using the same password as his user account.

![azure-robisl](assets/img/posts/worker-htb/robisl-devops.png)

We can now observe a new project which is `PartsUnlimited`.

For execute commands as Administrator, we now need to create a new build pipeline using Azure Pipelines. Click on __Pipelines__ on the left tab and click on __Builds > New Pipeline > Azure Repos Git > PartsUnlimited > Starter Pipeline__  and add the following contents to azure-pipelines.yaml:

```yaml
# Starter pipeline
# Start with a minimal pipeline that you can customize to build and deploy your code.
# Add steps that build, run tests, deploy, and more:
# https://aka.ms/yaml

trigger:
- master

steps:
- powershell: |
   whoami
   type C:\Users\Administrator\Desktop\root.txt
  displayName: 'Run a one-line script'

- script: |
    echo Add other tasks to build, test, and deploy your project.
    echo See https://aka.ms/yaml
  displayName: 'Run a multi-line script'

```
I removed "Pool: 'Default'" from here because the pool doesn't exist and can cause problems with the build and added the line `type C:\Users\Administrator\Desktop\root.txt` to read the file, you can also put a reverse shell one-liner to get shell with Administrator privileges.

Click on __Save and Run__ and click on *Create a new branch* option and lastly, __Save and Run__ again. It'll create a new branch and starting the build pipeline, we can read the output once it is done.

It used the agent `Hamilton11` and the default pool: 'Setup'.

> Agent pools are there so you can share agent machines across projects and in this case we used default pool to queue our job of running a simple script.

![build-complete](assets/img/posts/worker-htb/build-complete.png)

Click on "Run a one-liner script" and read the root flag!

![root-flag](assets/img/posts/worker-htb/read-root-flag.png)

We got root flag! 

We did it, let's now understand "Pipelines" and how they actually work.

#### Understanding DevOps Pipelines <a name="understanding-pipelines">

In software engineering, this term is very popular. Pipelines are a set of practices that are used in testing and deployment of software. Most of the practices in software engineering are quite common and hence we can automate those things by using Pipelines. They essentially build, test and deploy applications very fast and makes the whole deployment process efficient and organized. There can be several stages in a pipeline which uses different test cases given by developers. There are many frameworks which can help in creating DevOps pipelines such as **Jenkins**, **Travis CI**, **Circle CI**, **TeamCity** etc.

**This was it! A really fun box, I got to use Azure DevOps for the first time. Hope you liked this walkthrough and feel free to contact me on my socials for feedback, suggestions!** [Contact Me](/contact)

[Back to Top](#top)