GOC=go build
GOFLAGS=-a -ldflags '-s'
CGOR=CGO_ENABLED=0

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
		--net=host \
		blackhole.aci

clean:
	rm -rf bin/ \
		appc* \
		blackhole \
		blackhole.aci \
		blackhole-layout
