GOC=go build
GOFLAGS=-a -ldflags '-s'
CGOR=CGO_ENABLED=0
DOCKER_NAME=unixvoid/blackhole

all: blackhole

blackhole:
	$(GOC) blackhole.go

run:
	go run blackhole.go

stat:
	mkdir -p bin/
	$(CGOR) $(GOC) $(GOFLAGS) -o bin/blackhole blackhole.go

dependencies:
	go get github.com/miekg/dns
	go get gopkg.in/gcfg.v1
	go get gopkg.in/redis.v5
	go get github.com/unixvoid/glogger

aci: stat
	wget https://github.com/appc/spec/releases/download/v0.8.7/appc-v0.8.7.tar.gz
	tar -zxf appc-v0.8.7.tar.gz
	mkdir -p blackhole-layout/rootfs/
	cp bin/blackhole blackhole-layout/rootfs/
	cp config.gcfg blackhole-layout/rootfs/
	cp deps/manifest.json blackhole-layout/manifest
	./appc-v0.8.7/actool build blackhole-layout blackhole.aci
	rm -rf appc*

test_rkt:
	sudo rkt run \
		--insecure-options=image \
		--port=dns-tcp:8053 \
		--port=dns-udp:8053 \
		blackhole.aci

docker: stat
	mkdir -p stage.tmp/
	cp deps/Dockerfile stage.tmp/
	cp bin/blackhole stage.tmp/
	cd stage.tmp && \
		sudo docker build -t $(DOCKER_NAME) .

clean:
	rm -rf bin/ \
		appc* \
		blackhole \
		blackhole.aci \
		blackhole-layout \
		stage.tmp
