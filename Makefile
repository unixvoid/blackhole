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

aci: stat
	mkdir -p blackhole-layout/rootfs/
	cp bin/blackhole blackhole-layout/rootfs/
	cp config.gcfg blackhole-layout/rootfs/
	cp deps/manifest.json blackhole-layout/manifest
	actool build blackhole-layout blackhole.aci

test_rkt:
	sudo rkt run \
		--insecure-options=image \
		--net=host \
		blackhole.aci

clean:
	rm -rf bin/ \
		blackhole \
		blackhole.aci \
		blackhole-layout
