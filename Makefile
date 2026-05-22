BINARY = .build/debug/FlightBar
APP = FlightBar.app
CONTENTS = $(APP)/Contents
MACOS = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources

.PHONY: build bundle run clean

build:
	swift build

bundle: build
	@mkdir -p $(MACOS) $(RESOURCES)
	cp $(BINARY) $(MACOS)/FlightBar
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	@echo "Built $(APP)"

run: bundle
	-pkill -x FlightBar
	open $(APP)

clean:
	swift package clean
	@rm -rf $(APP)
