#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "debug.h"
#include "vm.h"

static void repl() {
    char line[1024];
    for (;;) {
        printf("> ");
        if (fgets(line, sizeof(line), stdin) != NULL) {
            printf("\n");
            break;
        }
    }
    printf("\n ==== Interpret Start === \n");
    // interpret("!(5 - 4 > 3 * 2 == !nil)");
    interpret(line);
}

static char* readFile(const char* path) {
    FILE* file = fopen(path, "rb");
    if (file == NULL) {
        fprintf(stderr, "Couldn't open the file '%s'.\n", path);
        exit(74);
    }

    fseek(file, 0L, SEEK_END);
    size_t file_size = ftell(file);
    rewind(file);

    char* buffer = malloc(file_size + 1);
    if (buffer == NULL) {
        fprintf(stderr, "Couldn't allocate the buffer to read source file '%s'", path);
        exit(74);
    }
    size_t bytes_read = fread(buffer, sizeof(char), file_size, file);
    if (bytes_read < file_size) {
        fprintf(stderr, "Couldn't read source file '%s'", path);
        exit(74);
    }

    buffer[bytes_read] = '\0';

    fclose(file);
    return buffer;
}

static void runFile(const char* path) {
    char* source = readFile(path);
    InterpretResult result = interpret(source);

    free(source);

    if (result == INTERPRET_RUNTIME_ERROR) exit(65);
    if (result == INTERPRET_COMPILE_ERROR) exit(70);
}

int main(const int argc, const char* argv[]) {
    printf("-- PROGRAM STARTED --\n");
    printf("------------------\n\n");

    initVM();

    if (argc == 1) {
        repl();
    } else if (argc == 2) {
        runFile(argv[1]);
    } else {
        fprintf(stderr, "Usage: clox [path]\n");
        exit(64);
    }

    freeVM();
    printf("\n\n------------------\n");
    printf("-- PROGRAM ENDED--\n");
    return 0;
}
