#APP := $(shell basename $(shell git remote get-url origin))
#APPWIN := $(shell powershell -ExecutionPolicy Bypass -Command "(git remote get-url origin).Split('/')[-1]")
VERSION = $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
TARGETOS = linux #darwin linux
TARGETARCH = amd64 # arm64 x86
REGISTRY = ghcr.io/viacheslav-diachenko

#WINARCH = $(PROCESSOR_ARCHITEW6432)
#ifeq ($(WINTARGETARCH),AMD64)
#	TARGETARCH=amd64
#else ifeq ($(WINTARGETARCH),x86)
#	TARGETARCH=x86
#endif

# Detect the operating system
ifeq ($(OS),Windows_NT)
    TARGETOS = windows
	APP = $(shell powershell -ExecutionPolicy Bypass -Command "(git remote get-url origin).Split('/')[-1]")
	CGO_ENABLED = 0
	GOOS=windows
	CLEAR_GARBAGE=del

else
    CLEAR_GARBAGE=rm
	UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        TARGETOS = linux
		APP = $(shell basename $(shell git remote get-url origin))
    endif
    ifeq ($(UNAME_S),Darwin)
        TARGETOS = macOS
		APP = $(shell basename $(shell git remote get-url origin))
    endif
endif

# Detect the architecture
ifeq ($(TARGETOS),windows)
    TARGETARCH = $(shell wmic os get osarchitecture  | findstr /r /c:"64-bit" > nul && echo amd64 || echo x86)
else
    TARGETARCH = $(shell uname -m | sed 's/x86_64/amd64/' | sed 's/arm64/arm64/' | sed 's/aarch64/arm64/' | sed 's/i686/x86/')
endif

all:
	@echo "This is a Makefile for building a telegram bot app"
	@echo Detected OS: $(TARGETOS)
	@echo Detected Architecture: $(TARGETARCH)
	@echo Detected App name: ${APP}
	@echo Detected app version: ${VERSION}

format:
	gofmt -s -w ./

get:
	go get

test:
	go test -v

lint:
	golint

linux: format get		
	CGO_ENABLED=0 GOOS=linux GOTARGETARCH=${TARGETARCH} go build -v -o telegram_bot -ldflags "-X github.com/viacheslav-diachenko/telegram_bot/cmd.AppVersion=${VERSION}"

windows: format get	
	set "CGO_ENABLED=0" && set "GOOS=windows" && set "GOTARGETARCH=${TARGETARCH}" && go build -v -o telegram_bot.exe -ldflags "-X github.com/viacheslav-diachenko/telegram_bot/cmd.AppVersion=${VERSION}"

macOS: format get	
	CGO_ENABLED=0 GOOS=darwin GOTARGETARCH=${$TARGETARCH} go build -v -o telegram_bot -ldflags "-X github.com/viacheslav-diachenko/telegram_bot/cmd.AppVersion=${VERSION}"

image:
	docker build -t ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}_${TARGETARCH} --build-arg TARGETARCH=${TARGETARCH} -f Dockerfile.${TARGETOS} .

image_windows:
	docker build -t ${REGISTRY}/${APP}:${VERSION}-win_${TARGETARCH} --build-arg TARGETARCH=${TARGETARCH} -f Dockerfile.windows .

image_linux:
	docker build -t ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH} --build-arg TARGETARCH=${TARGETARCH} TARGETOS=${TARGETOS} -f Dockerfile.linux .

image_macos:
	docker build -t ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}  --build-arg TARGETARCH=${TARGETARCH} TARGETOS=${TARGETOS} f Dockerfile.linux . 

push:
	docker push ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}_${TARGETARCH}

push_windows:	
	docker push ${REGISTRY}/${APP}:${VERSION}-windows_${TARGETARCH}

push_linux:
	docker push ${REGISTRY}/${APP}:${VERSION}-linux_${TARGETARCH}

push_macos:
	docker push ${REGISTRY}/${APP}:${VERSION}-macos_${TARGETARCH}

clean:
	$(shell ${CLEAR_GARBAGE} telegram_bot*)
	docker rmi ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}_${TARGETARCH}

