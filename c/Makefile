CMAKE=cmake
BUILD_DIR=./build
ARGS=

run: build
	$(BUILD_DIR)/clox $(ARGS)

build:
	mkdir -p $(BUILD_DIR)
	$(CMAKE) -S . -B $(BUILD_DIR)
	$(CMAKE) --build $(BUILD_DIR)
	cp $(BUILD_DIR)/compile_commands.json compile_commands.json

clean:
	rm -f compile_commands.json
	rm -rf $(BUILD_DIR)

.PHONY: run build
