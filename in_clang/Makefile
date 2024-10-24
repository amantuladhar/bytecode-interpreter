CMAKE=CMAKE
BUILD_DIR=./build-debug


run: build-debug
	$(BUILD_DIR)/clox

build-debug:
	mkdir -p $(BUILD_DIR)
	$(CMAKE) -S . -B $(BUILD_DIR)
	$(CMAKE) --build $(BUILD_DIR)

.PHONY: run
