CONFIGURATION ?= release
BINARY = .build/$(CONFIGURATION)/FlightBar
APP = FlightBar.app
CONTENTS = $(APP)/Contents
MACOS = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources

.PHONY: build bundle run clean

build:
	swift build -c $(CONFIGURATION)

bundle: build
	@rm -rf $(APP)
	@mkdir -p $(MACOS) $(RESOURCES)
	cp $(BINARY) $(MACOS)/FlightBar
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp Resources/FlightBar.icns $(RESOURCES)/FlightBar.icns
	@echo "Built $(APP) from $(CONFIGURATION)"

run: bundle
	-pkill -x FlightBar
	open $(APP)

clean:
	swift package clean
	@rm -rf $(APP)
