# *config.json* Customisation for Networked Connections between QEWD and IRIS


The *config.json* file contains a number of parameters that modify the behaviour of
QEWD.  The main ones are described below:

## PoolSize

        "poolSize": 2,

- *poolsize*: allows you to specify the maximum number of Worker Processes that QEWD will create,
and hence the number of network connections QEWD will make to IRIS.  

  The network connections are actually managed by the 
[*mg-dbx*](https://github.com/chrisemunt/mg-dbx) module, 
which, in turn, communicates with the 
[*mgsi*](https://github.com/chrisemunt/mgsi) 
routines on IRIS which provide, in effect, an Open Source alternative to the
IRIS SuperServer.

  Unless the *poolPrefork* property is set to *true* (see later), QEWD only establishes the minimum number of concurrent connections needed
to service current incoming demand.  If a connection is unused for an hour, QEWD will shut it down automatically.

  If incoming requests arrive faster than can be serviced by the maximum number of connections specified
by the poolSize, they are queued in the QEWD Master Process.  If a queue of requests exists, when a
connection becomes free, QEWD dispatches the request at the top of the queue to the newly-available
connection.

The trick when using IRIS, therefore, is to keep the poolsize at or below your IRIS license limit.  Any excess traffic will be queued until a QEWD Worker Process and its associated connection to IRIS 
becomes available, and, as a result, you will therefore never run out of license slots when using QEWD.  

  As a rough rule of thumb, start with the poolsize equal to one less than the number of CPU cores
you have available **or** your maximum available IRIS license count, whichever is smaller.  By default, the poolsize is 1.  Remember that you will probably want to keep some IRIS license slots available for other
purposes.

  If you are using the IRIS Community Edition Docker Container, it is recommended that your *poolSize*
does not exceed 2 to avoid running out of its very limited number of available license slots.


## Port


        "port": 8080,

- *port*: the port on which QEWD's web server will listen. The *port* defaults to 8080.  

Note: if you are
running a Dockerised version of QEWD, the *port* property defines the port on which QEWD will listen
**within the Container*.  This may be mapped to a different physical port on the host system via the
*-p* parameters of the *docker run* command used to start the container.

The port you choose must be accessible by clients/browsers that use your QEWD system as a back-end.


## Management Password


        "managementPassword": "secret",

- *managementPassword*: this is used by the *qewd-monitor* and *qewd-monitor-adminui* 
applications to authenticate its use.  Defaults to *keepThisSecret!*.  It is recommended that you **always** specify your own password to prevent anyone trying the default.  Make sure your management password
is not guessable.


## Database Parameters

You should always specify:

          "database": {
            "type": "dbx",
            "params": {
              "database": "IRIS",
            }
          }

This makes sure that QEWD uses the *mg-dbx* connection interface to IRIS.

The remaining *params* values will be specific to your IRIS database setup, for example:


              "host": "192.168.1.100",
              "tcp_port": 7041,
              "username": "_SYSTEM",
              "password": "secret",
              "namespace": "USER"



- *host*: specifies the IP address or domain name of the machine on which you
are running IRIS.  

  Note: if you are running the Dockerised version of IRIS, then this is the IP
address or domain name of the host machine on which the Docker container is running.

- *tcp_port*: specifies the IRIS *mgsi* listener port.  This is defined when you start the
*mgsi* "Superserver" on your IRIS system, eg:

        %SYS> d start^%zmgsi(0)     Starts mgsi, listening on the default port 7041

        %SYS> d start^%zmgsi(7100)     Starts mgsi, listening on port 7100

  Note: if you are connecting to the Docker version of IRIS, you may have mapped the *mgsi* listener
port to a different physical port on the host in the *docker run* command used to
start the IRIS Container (eg -p 9093:7041).  If so, the *tcp_port* should be set to the **mapped**
port (eg 9093 in the example).


- *username*: Your IRIS system's Username.  "Out of the box", this is *_SYSTEM*

- *password*: Your IRIS system's password. "Out of the box", this is "SYS", but on production
systems you will have almost certainly changed this password.  Specify the password appropriate to
your IRIS system.

- *namespace*: the IRIS namespace to which QEWD will be connected.  Any Globals accessed by your QEWD
applications will reside in this namespace.  You may specify any namespace that exists and is configured
for use on your IRIS system.  For initial testing/development, *USER* is a good choice as it always
exists on IRIS installations.


# Optional Parameters

There are a number of other, optional parameters available for use in the *config.json* file:

- *serverName*: If specified, this is used by the *qewd-monitor* and *qewd-monitor-adminui* applications
as the name it displays for your QEWD system.  This is useful to set if you are running more than one
QEWD system, to confirm which one you are monitoring.  Defaults to *QEWD Server*.


- *poolPrefork*: defaults to *false*.  If set to *true*, the full number of connections 
specified by the *poolSize* property is established to IRIS immediately when QEWD is started. *ie* if
*poolSize* is set to 4 and *poolPrefork* is true, then QEWD will attempt to make all 4 connections
to IRIS when it is started up.

- *ssl*: It is possible to run a QEWD system securely, with connections to it from clients/browsers
only via SSL/HTTPS.  To do so, you'll need a valid SSL certificate in the form of two files:

  - the key file
  - the cert file

  If you have these available, you specify their file paths in the *config.json* file as sub-properties
of the *ssl* property, eg:

        "ssl": {
          "keyFilePath": "/opt/qewd/ssl/ssl.key",
          "certFilePath": "/opt/qewd/ssl/ssl.cert"
        }


  Note that a common alternative is to put QEWD behind a reverse proxy such as NGINX which looks
after outward-facing traffic.  In such a scenario, NGINX would be configured to handle the SSL traffic, 
with requests proxied to the QEWD system over an HTTP (in the clear) connection between NGINX and QEWD.
Of course, in such a scenario, the QEWD system would be firewalled to prevent any external access, and
limited to access via NGINX.

- *cors*: defaults to *false*.  If set to *true*, then QEWD will automatically add the expected
set of CORS response
headers to every outgoing HTTP response.

- *bodyParser*: use this to specify an alternative Body Parser module from the standard one
used by Express (the web server module used by QEWD).  Alternatively, if you want to custom-configure the standard Body Parser module, you should specify set this property with a value of *body-paser*.  [See here for more details](https://github.com/robtweed/qewd/blob/master/up/docs/Life_Cycle_Events.md#addmiddleware)

- *max_queue_length*: QEWD's queue makes use of a very high performance module named 
[double-ended-queue](https://github.com/petkaantonov/deque).  When started, this needs to
be told the maximum size of queue it will need to handle.  The default value is 20000.  It is
unlikely that you will need to increase this value, but on a *very* busy system with limited access to
IRIS connections, you may need to increase it.

- *use_worker_threads*: defaults to *false*.  If set to *true*, QEWD will run any Worker Processes
as Node.js Worker Threads rather than Node.js Child Processes.  Communication between the QEWD Master Process
and Worker Threads is significantly faster than with Worker Child Processes.  However, when using
Worker Threads, *mg_dbx* has to serialise access to IRIS across all Worker Threads to ensure that only one Worker Thread can actually access IRIS at any one time.  So if there is a lot of concurrent database activity within multiple Worker Threads, this mode could end up being slower than using Child Processes.  If in doubt, stick to the default of using Child Processes, but it may be worth a bit of experimentation to see if Worker Threads improve performance for your workload characteristics.

- *sessionDocumentName*: by default this is *CacheTempEWDSession*.  In other words, all QEWD Session data is maintained in a Global on IRIS named ^CacheTempEWDSession*.  As its name prefix implies, this Global is automatically mapped by IRIS to IRISTEMP storage, and so is ephemeral and in-memory, but therefore very fast.

  If you want to use a different Global for QEWD Session storage, feel free to change this parameter and restart QEWD.



[Read here](https://github.com/robtweed/qewd/blob/master/up/docs/Config.md) for details on how to set up QEWD MicroServices using the *config.json* file settings.




