.PHONY: generate build test clean

SIMULATOR ?= "platform=iOS Simulator,name=iPhone 17"

generate:
	xcodegen

build: generate
	xcodebuild -scheme Farnsworth -destination $(SIMULATOR)

test: generate
	xcodebuild test -scheme Farnsworth -destination $(SIMULATOR)

clean:
	rm -rf Farnsworth.xcodeproj
	rm -rf .build
