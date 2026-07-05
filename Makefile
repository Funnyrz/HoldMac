.PHONY: build run app clean

build:
	swift build

run:
	swift run HoldMac

app: build
	rm -rf .build/文件中转桶.app
	mkdir -p .build/文件中转桶.app/Contents/MacOS
	mkdir -p .build/文件中转桶.app/Contents/Resources
	cp Resources/Info.plist .build/文件中转桶.app/Contents/Info.plist
	cp Resources/AppIcon.icns .build/文件中转桶.app/Contents/Resources/AppIcon.icns
	cp -R Resources/en.lproj .build/文件中转桶.app/Contents/Resources/
	cp -R Resources/zh-Hans.lproj .build/文件中转桶.app/Contents/Resources/
	cp .build/debug/HoldMac .build/文件中转桶.app/Contents/MacOS/HoldMac

clean:
	swift package clean
	rm -rf .build/文件中转桶.app
