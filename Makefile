.PHONY: generate build test clean lint

SIMULATOR ?= "platform=iOS Simulator,name=iPhone 17"

generate:
	xcodegen

build: generate
	xcodebuild -scheme Farnsworth -destination $(SIMULATOR)

test: generate
	xcodebuild test -scheme Farnsworth -destination $(SIMULATOR)

lint:
	swiftlint lint

clean:
	rm -rf Farnsworth.xcodeproj
	rm -rf .build
