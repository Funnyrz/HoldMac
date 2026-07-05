.PHONY: build run app dmg clean

BUILD_DIR := build
APP_NAME := 文件中转桶
APP_PATH := $(BUILD_DIR)/$(APP_NAME).app
SWIFT_BUILD := swift build --build-path $(BUILD_DIR)

build:
	$(SWIFT_BUILD)

run:
	swift run --build-path $(BUILD_DIR) HoldMac

app: build
	rm -rf $(APP_PATH)
	mkdir -p $(APP_PATH)/Contents/MacOS
	mkdir -p $(APP_PATH)/Contents/Resources
	cp Resources/Info.plist $(APP_PATH)/Contents/Info.plist
	cp Resources/AppIcon.icns $(APP_PATH)/Contents/Resources/AppIcon.icns
	cp -R Resources/en.lproj $(APP_PATH)/Contents/Resources/
	cp -R Resources/zh-Hans.lproj $(APP_PATH)/Contents/Resources/
	cp $(BUILD_DIR)/debug/HoldMac $(APP_PATH)/Contents/MacOS/HoldMac

dmg: app
	scripts/build-dmg.sh

clean:
	swift package clean
	rm -rf $(BUILD_DIR)
