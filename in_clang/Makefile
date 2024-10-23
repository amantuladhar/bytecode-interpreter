CMAKE=CMAKE

run: build-debug
	./cmake-build-debug/clox

build-debug:
	mkdir -p cmake-build-debug
	$(CMAKE) -S . -B ./cmake-build-debug
	$(CMAKE) --build ./cmake-build-debug

.PHONY: run
