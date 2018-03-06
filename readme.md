# Blackhole
[![Build Status (Travis)](https://travis-ci.org/unixvoid/blackhole.svg?branch=master)](https://travis-ci.org/unixvoid/blackhole)  
Blackhole is a DNS blackhole written in golang. The main point of this project is to be a small(statically compiled), 
portable binary with available container options if needed.

## Running blackhole
There are 3 main ways to run blackhole:

1. **Docker**: we have cryodns pre-packaged over on the [dockerhub](https://hub.docker.com/r/unixvoid/blackhole/), go grab the latest and run: 
`docker run -dp 53:53 unixvoid/blackhole`. This will now expose port 53 on the host running the blackhole.

2. **ACI/rkt**: we have public rkt images hosted on the site! check them out [here](https://cryo.unixvoid.com/bin/rkt/blackhole/) or go give us a fetch for 64bit machines!
`rkt fetch unixvoid.com/blackhole`.  This image can be run with rkt or you can
grab our handy [service file](https://github.com/unixvoid/blackhole/blob/master/deps/blackhole.service)

3. **From Source**: Are we not compiled for your architecture? Wanna hack on the source?  Lets bulid and deploy:  
  `make dependencies`  
  `make run`  
  If you want to build a docker use: `make docker`  
  If you want to build an ACI use: `make aci`

## Configuration
The configuration is very straightforward, we can take a look at the default
config file and break it down.
```
[blackhole]					# this section is the start of the servers main config.
	loglevel	= "debug"		# loglevel, this can be [debug, cluster, info, error]
	dnsport		= 53			# port for DNS listener to bind to

[redis]						# this section is the start of redis configurations
	useredis	= false			# weather or not to use redis at all
	host		= "localhost:6379"	# address and port of the redis server to be used
	password	= ""			# password for the redis server
```  
Note that redis can be used to log domains.  Set `useredis` to true and fill in the proper
redis configurations to turn this on.  This feature is mainly for auditing purposes and will
drop every queried domain into a redis entry named `index:domains`.
