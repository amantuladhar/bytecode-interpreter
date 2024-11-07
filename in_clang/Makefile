CMAKE=CMAKE
BUILD_DIR=./build-debug
ARGS=

run: build
	$(BUILD_DIR)/clox $(ARGS)

build:
	mkdir -p $(BUILD_DIR)
	$(CMAKE) -S . -B $(BUILD_DIR)
	$(CMAKE) --build $(BUILD_DIR)

.PHONY: run build
