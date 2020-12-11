# Installing QEWD with a Networked Connection to IRIS
 
Rob Tweed <rtweed@mgateway.com>  
11 December 2020, M/Gateway Developments Ltd [http://www.mgateway.com](http://www.mgateway.com)  

Twitter: @rtweed

Google Group for discussions, support, advice etc: [http://groups.google.co.uk/group/enterprise-web-developer-community](http://groups.google.co.uk/group/enterprise-web-developer-community)


# About this Repository

This repository provides instructions on how to install, configure and run QEWD,
using IRIS as the database, but where IRIS is on a different physical system to QEWD, and the
connection between QEWD and IRIS is over a network.

Note that although the instructions below are for IRIS, they will work with very little, if any,
change for Cach&eacute; also.


QEWD can be run in a variety of ways on a number of different Operating Systems:

- natively on Windows
- natively on Linux and Raspberry Pi
- as a Docker Container on Linux and Raspberry Pi

Instructions are included in this document for all these alternatives.


IRIS is supported on Windows, Linux, Unix and OS/X.  It is also available as a 
[Dockerised Community Edition](https://hub.docker.com/_/intersystems-iris-data-platform)
 that can be run on Linux.  The Dockerised version of IRIS can even run on a Raspberry Pi (3 or 4), provided a 64-bit Operating System has been installed (eg [Ubuntu 20.04](https://ubuntu.com/download/raspberry-pi))
and provided you use the ARM64 version of the IRIS Docker Container.

Please see the appropriate documentation from InterSystems for installing IRIS on your desired platform/Operating System.


# Setting Up IRIS

Regardless of the version, platform and Operating System you run IRIS on, in order for it to work with QEWD over a networked connection, you need to install the 
[*M/Gateway Service Integration Gateway (mgsi)*](https://github.com/chrisemunt/mgsi) routines.

*mgsi* is, in effect, an Open Source alternative to the IRIS SuperServer.


## Natively-Installed IRIS Systems

The easiest way to install these routines on a natively-running IRIS system is to first clone
the *mgsi* repository from Github.  Of course, you'll need to first make sure
you have [*git* installed](https://git-scm.com) on your Windows system.

Then, in a Windows Console session, from the directory of your choice, run:

        git clone https://github.com/chrisemunt/mgsi

This will create a sub-directory named *mgsi* under the directory you were in when you ran the *git clone* command.  Let's assume you've installed it into:

Linux:

        /home/ubuntu/mgsi

Windows:

        C:\mgsi

The routines you need are in a file within a subdirectory named *isc*.


Now, open an IRIS Terminal session and first switch to the %SYS namespace:

        USER> zn "%SYS"

        %SYS>


Then import and compile the *mgsi* routines (altering the paths as appropriate for your installation):

Linux:

        %SYS> d $system.OBJ.Load("/home/ubuntu/mgsi/isc/zmgsi_isc.ro","ck")

Windows:

        %SYS> d $system.OBJ.Load("c:\mgsi\isc\zmgsi_isc.ro","ck")


You can now check that they've installed correctly:

        %SYS> d ^%zmgsi

        M/Gateway Developments Ltd - Service Integration Gateway
        Version: 3.6; Revision 15 (6 November 2020)

The version and date may be higher/later than shown above.

Once you've installed the routines, you can delete the cloned *mgsi* repository directory.

Now skip forward to [start the *mgsi* SuperServer](#starting-the-mgsi-superserver).

----

## Dockerised Version of IRIS

There are various ways you can install the *mgsi* routines on the Dockerised version of IRIS, but
you can use the following approach (or adapt it to meet your particular needs)

### Prepare the IRIS Host

On the host system (ie on which you're going to run the IRIS Docker Container), create a directory that you'll use for mapping resources into the IRIS Container, for example:

        ~/resources

Next, clone the *mgsi* repository into this new directory:

        cd ~/resources
        git clone https://github.com/chrisemunt/mgsi


### Start the IRIS Container

If you're using the IRIS Community Edition Docker Container, start it, making sure you publish at least the following two ports:

- 52773: the IRIS web server port.  You'll need this to configure IRIS via the IRIS System Management Portal

- 7041: the default *mgsi* port, to which your *QEWD* system will connect

You may wish to map these to different external ports.

Start the IRIS Docker container, mapping the directory you created above to a directory within the IRIS container: */home/irisowner/mgweb*, for example:

        docker run --name my-iris -d --rm -p 9092:52773 -p 9093:7041 -v /home/ubuntu/resources:/home/irisowner/resources store/intersystems/iris-community:2020.3.0.221.0


Note: if you want to persist your IRIS database between Container restarts, you should also create another host directory for the IRIS database files, eg:

        ~/iris

and then start the IRIS container using this instead (modify the host directory paths appropriately):

        docker run --name my-iris -d --rm -p 9092:52773 -p 9093:7041 -v /home/ubuntu/resources:/home/irisowner/resources -v /home/ubuntu/iris:/durable --env ISC_DATA_DIRECTORY=/durable/iris store/intersystems/iris-community:2020.3.0.221.0


### Change the IRIS *_SYSTEM* Password

At this stage, it's a good idea to change the password for the IRIS user *_SYSTEM*.  You can do this in a number of ways (see the IRIS Docker documentation), but one of the ways is to connect to your IRIS Dockerised system via the System Management Portal.  Doing so will force you to change the password.  For the purposes of this document, I'll assume you changed the password to *secret*, but of course you'll want to use something rather less guessable!


### Install the *mgsi* Routines

When the IRIS Container has fully started, you can install the *mgsi* Routines.  First, open an
IRIS Terminal session within the IRIS Container:

        docker exec -it my-iris iris session IRIS

Next, switch to the *%SYS* namespace

        USER> zn "%SYS"

Then install the routines from the mapped directory

        %SYS> d $system.OBJ.Load("/home/irisowner/resources/mgsi/isc/zmgsi_isc.ro","ck")

You should see something like this:

        Load started on 12/02/2020 17:22:14
        Loading file /home/irisowner/resources/mgsi/isc/zmgsi_isc.ro as rtn
        %zmgsi.INT Loaded
        %zmgsis.INT Loaded
        Compiling routine : %zmgsi.int
        Compiling routine : %zmgsis.int
        Load finished successfully.

You can now check that they've installed correctly:

        %SYS> d ^%zmgsi

        M/Gateway Developments Ltd - Service Integration Gateway
        Version: 3.6; Revision 15 (6 November 2020)

The version and date may be higher/later than shown above.

----
Note: **provided you've set up the IRIS Container to map its database files to a host directory**,
if you wish, you can now shut down the IRIS Container and delete the cloned *mgsi* repository from the
host system.  Then restart the container, omitting the mapping of the *mgsi* host directory, but making sure you map the host's IRIS database directory, eg:

        docker run --name my-iris -d --rm -p 9092:52773 -p 9093:7041 -v /home/ubuntu/iris:/durable --env ISC_DATA_DIRECTORY=/durable/iris store/intersystems/iris-community:2020.3.0.221.0

----


## Starting the *mgsi* SuperServer

Before QEWD can access your IRIS system over a network connection, you need to start the *mgsi*
"SuperServer".  This will listen on a TCP port for incoming connection requests: by default
*mgsi* listens on port 7041, but you can choose any port you like.  Of course your network
and any associated firewalls must be configured so that your QEWD system can connect to the
*mgsi* listener port.

Note 1: if you are using the Dockerised version of IRIS, you may have mapped the *mgsi* port to a
different host port.  QEWD will need to connect to that mapped host port.

Note 2: you must start the *mgsi* "SuperServer" from the *%SYS* namespace.

Start an IRIS Terminal session.  If you are using the IRIS Container, if you haven't
already started a Terminal session, you do so by typing:

        docker exec -it my-iris iris session IRIS


To start it using the default port (7041):


        // if necessary:
        USER> zn "%SYS"
        // then...        


        %SYS> d start^%zmgsi(0)


If you want to use a different port, change the argument from 0 to the port you require, eg:

        %SYS> d start^%zmgsi(7100)


Note 3: To exit the IRIS Terminal, simply type *h* (ie *halt*) and hit the *Enter* key.

Note 4: Remember that if you stop and restart IRIS, you'll need to restart the *mgsi* SuperServer again.  You might want to set up an automated IRIS startup script to do this (refer to InterSystems documentation).

Note 5: In the instructions that follow, I'll be assuming that your IRIS system is listening on port 7041, and the IP address of the system on which IRIS is running (or the IRIS Container is running) is *192.168.1.100*.  Adjust the examples appropriately for your system/configuration.


IRIS is now ready for connection to QEWD.

----

# Setting up your QEWD System

The following will describe how to set up an absolutely minimal QEWD system that will connect to your IRIS database.  It won't include any application logic etc, but will include what's needed to run the *QEWD Monitor* applications.

However, the QEWD system will be ready for you to begin adding your own:

- REST APIs; and/or
- back-end handlers for interactive WebSocket-based applications

Remember that QEWD allows you to write all your logic in JavaScript, and use the IRIS database as "persistent JSON" as well as a multi-model database using the 
[QEWD-JSdb](https://github.com/robtweed/qewd-jsdb) abstraction.

If required, you can also invoke IRIS functions or Class Methods via the networked connection.


So let's get started and set up your QEWD system.  Follow the appopriate instructions below for your particular QEWD configuration/platform:

- [Native QEWD Installation on Windows](#native-qewd-installation-on-windows)
- [Native QEWD Installation on Linux, OS/X or Raspberry Pi](#native-qewd-installation-on-linux-osx-or-raspberry-pi)
- [Dockerised QEWD Installation on Linux or Raspberry Pi](#dockerised-qewd-installation-on-linux-or-raspberry-pi)

----

## Native QEWD Installation on Windows

### Install Node.js

You first need to [install Node.js](https://nodejs.org) on your Windows machine(s). Node.js versions 12.x and 14.x are supported.

Do not install earlier versions of Node.js, and if you already have an earlier version of Node.js
installed, you will need to update it.

### Clone this Repository

The easiest way to prepare your Windows System for running QEWD natively is to first clone
the this repository from Github.  Of course, you'll need to first make sure
you have [*git* installed](https://git-scm.com) on your Windows system.

Then, in a Windows Console session, from the directory of your choice, run:

        git clone https://github.com/robtweed/qewd-starter-kit-iris-networked

If you were in the root directory on your C: drive when you ran the *git clone* command,
you'll see that the repository has been cloned into *C:\qewd-starter-kit-iris-networked*.

The repository contains a ready-made set of QEWD installation files for Windows.  These are
in the */windows* folder.  So we're now going to create a QEWD Installation directory
on your Windows system from these.  In this tutorial, I'm going to create the QEWD
installation in the *C:\qewd* directory.  To do so, in the Windows Console session, type:


        move C:\qewd-starter-kit-iris-networked\windows c:\qewd


Modify this command appropriately for your requirements.

You'll now have a QEWD Installation directory (*C:\qewd*) that contains:

        C:\qewd
           |
           |- package.json
           |
           |- jsdb_shell.js
           |
           |- configuration
                  |
                  |- config.json


If you want, you can now remove the cloned repository directory (eg *C:\qewd-starter-kit-iris-networked*).



### Edit the *config.json* File

The file named *config.json* in your QEWD Installation directory, eg: *C:\qewd\configuration\config.json*,
tells QEWD how to set itself up and, critically, where to find the IRIS system on your network and how to
connect to it via its *mgsi* SuperServer.

The copy of *config.json* that has been created is a template version, and you'll need to edit it to
match your particular set-up.

You'll see that it's a file with JSON content:

        {
          "qewd": {
            "poolSize": 2,
            "port": 8080,
            "managementPassword": "secret",
            "database": {
              "type": "dbx",
              "params": {
                "database": "IRIS",
                "host": "192.168.1.100",
                "tcp_port": 7041,
                "username": "_SYSTEM",
                "password": "SYS",
                "namespace": "USER"
              }
            }
          }
        }


The only values you'll definitely need change for now are the following *qewd.database.params* values:

- *host*: the IP Address or domain name of the system on which your IRIS database is running
- *tcp_port*: the port on which the *mgsi* SuperServer is listening on your IRIS system.  If
you started this using the default port (7041), you can leave this value alone.


  **Note**: if you are running the IRIS Community Edition Docker version, when you started
its Container, you may have mapped the *mgsi* listener port to a different host port 
(eg using the *docker run* parameter *-p 9093:7041).  If so, the *tcp_port* value
in your *config.json* file should be the mapped host port (eg 9093).

You *may* also need to change the IRIS *password* value, particularly if you're using the
IRIS Community Edition Docker Container.


To find out more about these and other available properties in the *config.json*
file, see [the CONFIG documentation](./CONFIG.md) within this repository for details.

Save your edited version of the *config.json* file and you're ready to install QEWD.


### Install QEWD

In a Windows Command Prompt session, do the following:

        cd C:\qewd
        npm install


Node.js/NPM will use the information in the *package.json* file to install QEWD and its dependent modules.


When it is finished, the QEWD installation directory should now look like this:

        C:\qewd
           |
           |- jsdb_shell.js
           |
           |- package.json
           |
           |- package-lock.json
           |
           |- configuration
           |       |
           |       |- config.json
           |
           |- node_modules


If you look in the *node_modules* sub-directory you'll find all the Node.js modules used by QEWD.



### Start QEWD for the First Time

When you start QEWD for the first time, a number of further installation steps take place.

In the Windows Command Prompt Session, type:

        npm start

You should see the following:


        > qewd-up@1.0.0 start C:\qewd
        > node node_modules/qewd/up/run_native

        Installing mg-dbx interface module for Windows
        qewd-client installed
        mg-webComponents installed
        mg-dbx installed


The start process will then terminate.


Your QEWD Installation directory should now look like this:

        C:\qewd
           |
           |- package.json
           |
           |- package-lock.json
           |
           |- configuration
           |       |
           |       |- config.json
           |
           |- node_modules
           |
           |- www
           |    |
           |    |- mg-webComponents.js
           |    |
           |    |- qewd-client.js
           |    |
           |    |- components
           |    |      |
           |    |      |- adminui
           |    |      |
           |    |      |- d3
           |    |      |
           |    |      |- leaflet
           |    |
           |    |- qewd-monitor-adminui
           |    |      |
           |    |      |- js
           |    |      |
           |    |      |- index.html
           |    |      |
           |    |      |- Qewd_symbol_only.png
           |
           |
           |- qewd-apps
           |    |
           |    |- qewd-monitor-adminui


...with some of the sub-directories containing quite a few other files.

Basically what's been created is now enough to at least run the *qewd-monitor-adminui*
application when you start up QEWD.

The *www* sub-directory will be your QEWD system's Web Server Root Directory, so any files
within it will be available for fetching by a web browser.

The *qewd-apps* sub-directory is where QEWD interactive application message handler modules
reside.  It has installed a set of handlers for the application named *qewd-monitor-adminui*.

Your QEWD Windows system is now ready to fully start up.


### Starting QEWD

In the Windows Command Prompt Session, once more type:

        npm start


This time, QEWD will start up.  You'll see quite a lengthy log report, but it should end with:

        routes: []
        Double ended queue max length set to 20000
        webServerRootPath = C:\qtest/www/
        Worker Bootstrap Module file written to node_modules/ewd-qoper8-worker.js
        ========================================================
        ewd-qoper8 is up and running.  Max worker pool size: 2
        ========================================================
        ========================================================
        QEWD.js is listening on port 8080
        ========================================================


Your QEWD Windows system is now ready for use.  
Skip forwards  to the [next section on Testing your QEWD system](#testing-qewd).

----


## Native QEWD Installation on Linux, OS/X or Raspberry Pi
 
The following steps should work on machines running Linux or OS/X, or
on Raspberry Pis running Raspbian, Raspberry Pi OS or Ubuntu 20.04.

You may need to adjust some of the file paths or system utility names depending
on the Operating System you're using.  The examples below are for Ubuntu, Debian Linux
or Raspberry Pi.


### Initial Steps / Pre-requisites

#### Make Sure you have *git* Installed

If you haven't already installed *git* on your Linux system or Rasperry Pi, install it now, eg:

        sudo apt-get install git


#### Clone This Repository

Clone this repository to your Linux system or Raspberry Pi.  For example, to clone it
to the folder *~/qewd-starter-kit-iris-networked* on your machine:

        cd ~
        git clone https://github.com/robtweed/qewd-starter-kit-iris-networked


The repository contains a ready-made set of QEWD installation files for 
Linux or the Raspberry Pi.  These are
in the */linux-rpi* folder.  So we're now going to create a QEWD Installation directory
on your Linux system from these.  In this tutorial, I'm going to create the QEWD
installation in the *~/qewd* directory.  To do so, in a Linux Terminal session, type:


        mv ~/qewd-starter-kit-iris-networked/linux-rpi ~/qewd


Modify this command appropriately for your requirements.

You'll now have a QEWD Installation directory (*~/qewd*) that contains:

        ~/qewd
           |
           |- package.json
           |
           |- jsdb_shell.js
           |
           |- install_node.js
           |
           |- configuration
                  |
                  |- config.json



The instructions that follow in this tutorial will assume your QEWD Installation directory is
*~/qewd*.  Adjust the paths in the examples appropriately
if you're using a different directory on your Linux system.


If you want, you can now remove the cloned repository directory (eg *~/qewd-starter-kit-iris-networked*).


#### Dependencies

QEWD has two key dependencies:

- Node.js must be installed.  The latest version 14 is recommended, but QEWD will also run
satisfactorily with versions 10 and 12.

- The [mg-dbx](https://github.com/chrisemunt/mg-dbx) interface module used by QEWD 
to connect to IRIS has to be built from
source during installation.  This assumes that a C++ compiler in available in your Linux
system.

To satisfy these dependencies:


##### Install Node.js

If you don't have Node.js installed, the simplest approach is to use the 
[installation script](./install_node.sh)
that you'll find within your QEWD Installation directory.  This has been tested with Ubuntu Linux and
Raspberry Pi Operating Systems.


It will install the latest version 14.x build.  Simply type:

        cd ~/qewd
        source install_node.sh

You can test if it installed correctly by typing:

        node -v

If everything worked correctly, it should return the installed version, eg:

        v14.15.1


If you are using OS/X, you should download the appropriate
[Node.js installer](https://nodejs.org).


##### Install a C++ Compiler

On Ubuntu or Raspberry Pi, you can do this by running the following commands:

        sudo apt-get update
        sudo apt-get install build-essential


These commands are safe to type even if you're unsure whether or not you've already
installed a C++ compiler on your Linux machine.

On other Linux systems or OS/X you'll need to use the appropriate equivalent commands.


### Edit the *config.json* File

The file named *config.json* in your QEWD Installation directory, eg: *~/qewd/configuration/config.json*,
tells QEWD how to set itself up and, critically, where to find the IRIS system on your network and how to
connect to it via its *mgsi* SuperServer.

The copy of *config.json* that has been created is a template version, and you'll need to edit it to
match your particular set-up.

You'll see that it's a file with JSON content:

        {
          "qewd": {
            "poolSize": 2,
            "port": 8080,
            "managementPassword": "secret",
            "database": {
              "type": "dbx",
              "params": {
                "database": "IRIS",
                "host": "192.168.1.100",
                "tcp_port": 7041,
                "username": "_SYSTEM",
                "password": "SYS",
                "namespace": "USER"
              }
            }
          }
        }


The only values you'll definitely need change for now are the following *qewd.database.params* values:

- *host*: the IP Address or domain name of the system on which your IRIS database is running
- *tcp_port*: the port on which the *mgsi* SuperServer is listening on your IRIS system.  If
you started this using the default port (7041), you can leave this value alone.


  **Note**: if you are running the IRIS Community Edition Docker version, when you started
its Container, you may have mapped the *mgsi* listener port to a different host port 
(eg using the *docker run* parameter *-p 9093:7041).  If so, the *tcp_port* value
in your *config.json* file should be the mapped host port (eg 9093).

You *may* also need to change the IRIS *password* value, particularly if you're using the
IRIS Community Edition Docker Container.


To find out more about these and other available properties in the *config.json*
file, see [the CONFIG documentation](./CONFIG.md) within this repository for details.

Save your edited version of the *config.json* file and you're ready to install QEWD.


### Install QEWD and its Dependencies

Installation of QEWD is a one-off step that makes use of the *package.json* file
in your QEWD Installation directory.

Simply type:

        cd ~/qewd
        npm install


All the dependent Node.js modules used by QEWD will be installed into a new folder named *node_modules*.  
On completion, your *~/qewd* folder should now contain:

        ~/qewd
            |
            |_ package.json
            |
            |_ package-lock.json
            |
            |_ configuration
            |
            |- node_modules



#### Starting QEWD for the First Time


The second part of QEWD's installation is performed automatically when you start QEWD up
for the very first time.  Type:

        cd ~/qewd
        npm start

You should see the following:


        > qewd-up@1.0.0 start /home/rtweed/qewd
        > node node_modules/qewd/up/run_native
        
        mg-webComponents installed
        qewd-client installed
        
        *** Installation Completed.  QEWD will halt ***
        *** Please restart QEWD again using "npm start"

and you'll be returned to the Linux shell prompt.

If you now check your ~/qewd folder, you'll find it contains:


        ~/qewd
            |
            |_ package.json
            |
            |_ package-lock.json
            |
            |_ configuration
            |
            |- node_modules
            |
            |- qewd-apps
            |      |
            |      |- qewd-monitor-adminui
            |
            |- www
            |   |
            |   |- components
            |   |
            |   |- qewd-monitor-adminui
            |   |
            |   |- mg-webComponents.js
            |   |
            |   |- qewd-client.js


Everything QEWD needs to run should now be present.


#### Starting QEWD

Every time you want to start QEWD, simply type:

        cd ~/qewd
        npm start


QEWD will start up.  You'll see quite a lengthy log report, but it should end with:

        routes: []
        Double ended queue max length set to 20000
        webServerRootPath = /home/ubuntu/qewd/www/
        Worker Bootstrap Module file written to node_modules/ewd-qoper8-worker.js
        ========================================================
        ewd-qoper8 is up and running.  Max worker pool size: 2
        ========================================================
        ========================================================
        QEWD.js is listening on port 8080
        ========================================================


Your QEWD system is now ready for use.  
Skip forwards  to the [next section on Testing your QEWD system](#testing-qewd).

----


## Dockerised QEWD Installation on Linux or Raspberry Pi

Probably the quickest and simplest way of running QEWD is by using the
pre-built Dockerised version, which is available for both Linux systems
and the Raspberry Pi.


### Pre-requisites

#### Make Sure Docker is Installed

In order to run the Dockerised version of QEWD, the only key dependency is that you
have Docker installed.

Although you can run Docker Containers on Windows and OS/X, the mechanics are somewhat
clumsy and it's all a bit awkward to use.  Feel free to find out how to use Docker on
Windows or OS/X if you want to try it out.

Howver, Docker is a lot simpler and slicker to use on Linux machines and on the Raspberry Pi, and
the instructions that follow assume these are the systems you'll be using.

If you don't already have Docker installed, there are two main ways to install it.  
The easy way is to do this:

        sudo apt-get install docker.io

You may not get the most up to date version of Docker if you use this approach, but it's
usually perfectly adequate.

The alternative approach is to do the following:

      curl -sSL https://get.docker.com | sh


Whichever method you use to install Docker, by default, it 
will require *root* priveleges to use its commands, requiring the use of
the *sudo* prefix before the *docker* command.

To avoid this, you can do the following:

        sudo usermod -aG docker ${USER}
        su - ${USER}
        
  NB: You'll be asked to enter your user's password

Now you can simply use the *docker* command.



#### Make Sure you have *git* Installed

In the next step, you're going to use the *git clone* command, so you'll need
to make sure that *git* is installed on your system.

If you haven't already installed *git* on your Linux system or Rasperry Pi, install it now, eg:

        sudo apt-get install git


### Create a QEWD Installation Directory

This is most easily done as follows:

First, clone this repository to your Linux system or Raspberry Pi.  For example, to clone it
to the folder *~/qewd-starter-kit-iris-networked* on your machine:

        cd ~
        git clone https://github.com/robtweed/qewd-starter-kit-iris-networked


The repository contains a ready-made set of QEWD installation files for 
a minimal Containerised QEWD system:

- if you are running Linux, they are in the */docker-linux* directory
- if you are running a Raspberry Pi, they are in the */docker-rpi* directory

So we're now going to create a QEWD Installation directory
on your system from these.  In this tutorial, I'm going to create the QEWD
installation in the *~/qewd* directory.  To do so, in a Terminal session, type:

- Linux

        mv ~/qewd-starter-kit-iris-networked/docker-linux ~/qewd

- Raspberry Pi

        mv ~/qewd-starter-kit-iris-networked/docker-rpi ~/qewd


Modify this command appropriately for your requirements.

You'll now have a QEWD Installation directory (*~/qewd*) that contains:

        ~/qewd
           |
           |- jsdb_shell.js
           |
           |- start.sh
           |
           |- configuration
                  |
                  |- config.json



The instructions that follow in this tutorial will assume your QEWD Installation directory is
*~/qewd*.  Adjust the paths in the examples appropriately
if you're using a different directory on your Linux system or Raspberry Pi.


If you want, you can now remove the cloned repository directory (eg *~/qewd-starter-kit-iris-networked*).


### Edit the *config.json* File

The file named *config.json* in your QEWD Installation directory, eg: *~/qewd/configuration/config.json*,
tells QEWD how to set itself up and, critically, where to find the IRIS system on your network and how to
connect to it via its *mgsi* SuperServer.

The copy of *config.json* that has been created is a template version, and you'll need to edit it to
match your particular set-up.

You'll see that it's a file with JSON content:

        {
          "qewd_up": true,
          "qewd": {
            "poolSize": 2,
            "port": 8080,
            "managementPassword": "secret",
            "database": {
              "type": "dbx",
              "params": {
                "database": "IRIS",
                "host": "192.168.1.100",
                "tcp_port": 7041,
                "username": "_SYSTEM",
                "password": "SYS",
                "namespace": "USER"
              }
            }
          }
        }


The only values you'll definitely need to change for now are the following *qewd.database.params* values:

- *host*: the IP Address or domain name of the system on which your IRIS database is running
- *tcp_port*: the port on which the *mgsi* SuperServer is listening on your IRIS system. If
you started this using the default port (7041), you can leave this value alone.

  **Note**: if you are running the IRIS Community Edition Docker version, when you started
its Container, you may have mapped the *mgsi* listener port to a different host port 
(eg using the *docker run* parameter *-p 9093:7041).  If so, the *tcp_port* value
in your *config.json* file should be the mapped host port (eg 9093).

You *may* also need to change the IRIS *password* value, particularly if you're using the
IRIS Community Edition Docker Container.


To find out more about these and other available properties in the *config.json*
file, see [the CONFIG documentation](./CONFIG.md) within this repository for details.

Save your edited version of the *config.json* file and you're ready to start
the QEWD Docker Container.


### Download the QEWD Docker Container

Strictly-speaking, this step isn't completely necessary, since Docker will download the
QEWD Container automatically the first time you try to run it.

To manually download the QEWD Docker Container, do the following (you can be in
any directory when you run this):

Linux:

        docker pull rtweed/qewd-server

Raspberry Pi:

        docker pull rtweed/qewd-server-rpi


Enhancements are constantly being made to the QEWD Docker Container, and it's always a good
idea to be using the latest version.  Use the *docker pull* commands above to
ensure you always have the latest version.  If you already have the latest version, 
*docker pull* will tell you and abort.


### Starting the QEWD Docker Container


The idea is that you map your QEWD Installation Directory (containing the */configuration/config.json*
file) into a directory within the Container named */opt/qewd/mapped*.

The first time you try it out, I recommend you run the Docker Container as
a foreground, interactive process:

Linux:

        docker run -it --name qewd --rm -p 3000:8080 -v /home/ubuntu/qewd:/opt/qewd/mapped rtweed/qewd-server

Change the QEWD installation directory (shown as */home/ubuntu/qewd* above) to match the absolute path
for your Linux server.  Note that volume mapping paths must be absolute paths - ie *~/qewd* will 
not work.


Raspberry Pi:

        docker run -it --name qewd --rm -p 3000:8080 -v /home/pi/qewd:/opt/qewd/mapped rtweed/qewd-server-rpi


In both the examples above, the QEWD back-end will be accessible via the host system's port 3000.  Change
the *-p* parameter if you want to use a different port on your host system.  Make sure, however,
that the internal port (ie within the Container) is 8080, since that's what you specified QEWD
should use in your *config.json* file.

-----
Note: in your QEWD Installation directory you'll find a script file named *start.sh*.  This contains
a template version of the *docker run* command for your system which you can edit and then use
instead of typing the commands above.  After editing it, you can run it as follows:

        source start.sh
-----

QEWD will start running in the Container, and you'll see a lengthy log report, finishing with:

        Starting QEWD
        Double ended queue max length set to 20000
        webServerRootPath = /opt/qewd/mapped/www/
        Worker Bootstrap Module file written to node_modules/ewd-qoper8-worker.js
        ========================================================
        ewd-qoper8 is up and running.  Max worker pool size: 2 
        ========================================================
        ========================================================
        QEWD.js is listening on port 8080
        ========================================================


Your QEWD system is now ready for use.  

----

# Testing QEWD

## Try out the QEWD Monitor Application

The simplest way to confirm that QEWD is working correctly is to try running the
*QEWD Monitor* application.  This will have already been installed for you.

Start up the QEWD Monitor application in a browser using the URL shown below,
replacing *xx.xx.xx.xx* with the IP address or domain name of the machine on which
you are running QEWD (or the QEWD Container).:

- Native QEWD system on Windows, Linux, Raspberry Pi:

        http://xx.xx.xx.xx:8080/qewd-monitor-adminui

  *Note: if you changed the QEWD port value in your *config.json* file, you'll need to
change the port in the URL above*.


- Docker QEWD system:

        http://xx.xx.xx.xx:3000/qewd-monitor-adminui

  Note: if you mapped the QEWD Listener port in the *docker run* command to a different port
(eg -p 8081:8080), you'll need to change the port in the URL above to the mapped host port.


You should see the *QEWD Monitor* login screen and prompt.  Use the *managementPassword*
value that was specified in your *config.json* file (by default it was set to *secret*).

You should now see the *About* overview page which will confirm the versions you are using
of various critical components.  In particular, you should check the *Database* value.
This should confirm that you are indeed accessing your IRIS database, eg:

        IRIS version: 2020.3 build 221

If you aren't seeing this, or if you see database access errors appearing in the
QEWD process log, then you probably haven't configured the database connection
settings correctly in your *config.json* file.  If so:

- shut down the QEWD process (CTRL & C is sufficient to do this);
- edit the */configuration/config.json* file
- restart the QEWD process (either using *npm start* or the *docker run* command, depending on
your QEWD version)


However, if IRIS is displaying as your database, then congratulations!  Everything is working 
correctly.  Try some of the other options in the QEWD Monitor menu panel.  You can:

- view the QEWD Master and Worker Processes, and optionally stop them
- view and explore your IRIS database (using a tree view or a graphical view)
- view and explore active QEWD Sessions, and optionally terminate them


## Check on your IRIS System

When you start up the *QEWD Monitor* application, even before you actually enter the
Management Password, QEWD has already set up a QEWD Session on your IRIS system.  A 
QEWD Session is represented by data in the QEWD Session Global which, by default, is
a Global named *CacheTempEWDSession*.  You can [change this in your *config.json* file](./CONFIG.md)
if you wish.

So, use your favourite tool for viewing IRIS Globals and look for the *^CacheTempEWDSession* Global.

----

# QEWD-JSdb

QEWD uses a built-in abstraction of your IRIS database, known as 
[QEWD-JSdb](https://github.com/robtweed/qewd-jsdb).  When you explore your IRIS
database using the *QEWD-Monitor* application, it's all being done via the
QEWD-JSdb abstraction.

One of the things that has been included in your QEWD Installation directory is a file
named *jsdb_shell.js*.  This is a Node.js module that allows you to access and use
the QEWD-JSdb abstraction of your connected IRIS database, interactively from within the
Node.js REPL (ie the Node.js interactive shell).

Using QEWD-JSdb in this way is a great way to familiarise yourself with how it works, and
provides a *playground* where you can try things out during REST API development or interactive
message handler development.

Find out all the details in the [REPL Document](./REPL).



# Stopping QEWD

if you're running QEWD as a foreground process in a terminal window, you can simply type *CTRL&C* to stop
QEWD.

if you're running the Dockerised version of QEWD, you can use:

        docker stop qewd

Alternatively you can stop QEWD from within the *Qewd Monitor* application.
In the Processes screeen, click the stop button next to the *Master* process.  QEWD will
shut down and the *QEWD Monitor* application will no longer work.


# Start Developing

Now that you have QEWD up and running with IRIS, you can begin developing both
REST APIs and/or interactive/WebSocket applications.

Your QEWD system can support both at once, and you can develop and run as many REST APIs as you
wish and as many simultaneous interactive applications as you wish.

From this point onwards, there's no difference in how you develop QEWD applications,
regardless of the version of QEWD you're using, the Operating System you're using or
even the version of Node.js you use.  The only difference will be in file paths.

So you can now use the following tutorials:

- to develop REST APIs, get started with [this document](./REST.md)

- [this tutorial](./INTERACTIVE.md)
explains how to develop interactive applications using the *qewd-client* browser module.
This is a useful tutorial to take as it will help to explain the basics of how
QEWD supports interactive, WebSocket message-based applications, and how you handle those messages
in your browser's logic.  Note that your version of QEWD includes the *qewd-client* module.

- once familiar with the basics covered in the tutorial above, 
can can find out how to develop a modern interactive WebSocket application whose front-end uses the  
[*mg-webComponents*](https://github.com/robtweed/mg-webComponents) framework
that has also been automatically installed in your QEWD system.
[See this document, starting at the *mg-webComponents Framework* section](https://github.com/robtweed/qewd-microservices-examples/blob/master/WINDOWS-IRIS-2.md#the-mg-webcomponents-framework)


-----

## License

 Copyright (c) 2020 M/Gateway Developments Ltd,                           
 Redhill, Surrey UK.                                                      
 All rights reserved.                                                     
                                                                           
  http://www.mgateway.com                                                  
  Email: rtweed@mgateway.com                                               
                                                                           
                                                                           
  Licensed under the Apache License, Version 2.0 (the "License");          
  you may not use this file except in compliance with the License.         
  You may obtain a copy of the License at                                  
                                                                           
      http://www.apache.org/licenses/LICENSE-2.0                           
                                                                           
  Unless required by applicable law or agreed to in writing, software      
  distributed under the License is distributed on an "AS IS" BASIS,        
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
  See the License for the specific language governing permissions and      
   limitations under the License.      
