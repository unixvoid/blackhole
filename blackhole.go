package main

import (
	"fmt"
	"io/ioutil"
	"net"
	"os"

	"github.com/miekg/dns"
	"github.com/unixvoid/glogger"
	"gopkg.in/gcfg.v1"
	"gopkg.in/redis.v5"
)

type Config struct {
	Blackhole struct {
		Loglevel string
		DNSPort  int
	}
	Redis struct {
		UseRedis bool
		Host     string
		Password string
	}
}

var (
	config = Config{}
)

func main() {
	readConf()
	initLogger(config.Blackhole.Loglevel)

	redisClient, redisErr := initRedisConnection()
	if redisErr != nil {
		// only print if we are using redis
		if config.Redis.UseRedis {
			glogger.Error.Println("redis connection cannot be made.")
			glogger.Error.Println("cryodns will continue to function in passthrough mode only")
		}
	} else {
		// only print if we are using redis
		if config.Redis.UseRedis {
			glogger.Debug.Println("connection to redis succeeded.")
		}
	}
	println(` _   _         _   _       _     
| |_| |___ ___| |_| |_ ___| |___ 
| . | | .'|  _| '_|   | . | | -_|
|___|_|__,|___|_,_|_|_|___|_|___|`)
	if config.Redis.UseRedis {
		println("Running with redis connection..")
	} else {
		println("Running in standalone mode..")
	}

	// format the string to be :port
	fPort := fmt.Sprint(":", config.Blackhole.DNSPort)

	udpServer := &dns.Server{Addr: fPort, Net: "udp"}
	tcpServer := &dns.Server{Addr: fPort, Net: "tcp"}
	glogger.Info.Println("started server on", config.Blackhole.DNSPort)

	dns.HandleFunc(".", func(w dns.ResponseWriter, req *dns.Msg) {
		// reutrn nonexistent reply  to all requests
		hostname := req.Question[0].Name

		glogger.Debug.Printf("request received: %s", hostname)
		glogger.Debug.Printf("%v\n", req)

		rr := new(dns.A)
		rr.Hdr = dns.RR_Header{Name: hostname, Rrtype: dns.TypeA, Class: dns.ClassINET, Ttl: 1}
		rr.A = net.ParseIP("")

		// craft reply
		rep := new(dns.Msg)
		rep.SetReply(req)
		rep.SetRcode(req, dns.RcodeNameError)
		rep.Answer = append(rep.Answer, rr)

		// send it
		w.WriteMsg(rep)

		// add hostname to redis db
		if config.Redis.UseRedis {
			redisClient.SAdd("index:domains", hostname)
		}
	})

	go func() {
		glogger.Error.Println(udpServer.ListenAndServe())
	}()
	glogger.Error.Println(tcpServer.ListenAndServe())
}

func readConf() {
	// init config file
	err := gcfg.ReadFileInto(&config, "config.gcfg")
	if err != nil {
		panic(fmt.Sprintf("Could not load config.gcfg, error: %s\n", err))
	}
}

func initLogger(logLevel string) {
	// init logger
	if logLevel == "debug" {
		glogger.LogInit(os.Stdout, os.Stdout, os.Stdout, os.Stderr)
	} else if logLevel == "cluster" {
		glogger.LogInit(os.Stdout, os.Stdout, ioutil.Discard, os.Stderr)
	} else if logLevel == "info" {
		glogger.LogInit(os.Stdout, ioutil.Discard, ioutil.Discard, os.Stderr)
	} else {
		glogger.LogInit(ioutil.Discard, ioutil.Discard, ioutil.Discard, os.Stderr)
	}
}

func initRedisConnection() (*redis.Client, error) {
	// init redis connection
	redisClient := redis.NewClient(&redis.Options{
		Addr:     config.Redis.Host,
		Password: config.Redis.Password,
		DB:       0,
	})

	_, redisErr := redisClient.Ping().Result()
	return redisClient, redisErr
}
