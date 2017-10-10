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

clean:
	rm -rf bin/
	rm -rf blackhole
