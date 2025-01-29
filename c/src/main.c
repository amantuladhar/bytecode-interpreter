#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "chunk.h"
#include "common.h"
#include "debug.h"
#include "vm.h"

static void repl();
static void runFile(const char* path) ;
static char* readFile(const char* path);

int main(int argc, char** argv) {
    (void)argc;
    (void)argv[0];

    VM_init();

    if (argc == 1) {
        repl();
    } else if(argc == 2) {
        runFile(argc[1]);
    } else {
        fprintf(stderr, "Usage: clox [path]\n");
        exit(64);
    }

    /*Chunk chunk;*/
    /*Chunk_init(&chunk);*/
    /**/
    /*int constant = Chunk_addConstant(&chunk, 1.2);*/
    /*Chunk_write(&chunk, OP_CONSTANT, 123);*/
    /*Chunk_write(&chunk, constant, 123);*/
    /**/
    /*constant = Chunk_addConstant(&chunk, 2.8);*/
    /*Chunk_write(&chunk, OP_CONSTANT, 123);*/
    /*Chunk_write(&chunk, constant, 123);*/
    /**/
    /*Chunk_write(&chunk, OP_ADD, 123);*/
    /**/
    /*constant = Chunk_addConstant(&chunk, 2);*/
    /*Chunk_write(&chunk, OP_CONSTANT, 123);*/
    /*Chunk_write(&chunk, constant, 123);*/
    /**/
    /*Chunk_write(&chunk, OP_DIVIDE, 123);*/
    /**/
    /*Chunk_write(&chunk, OP_NEGATE, 123);*/
    /**/
    /*Chunk_write(&chunk, OP_RETURN, 123);*/
    /*printf("\n\n======== Disassemble Chunk =============\n\n");*/
    /*disassembleChunk(&chunk, "test chunk");*/
    /*printf("\n==========================================\n");*/
    /**/
    /*printf("\n\n======== Interpret =============\n\n");*/
    /*VM_interpret(&chunk);*/
    /*printf("\n==================================\n");*/

    VM_free();
    // Chunk_free(&chunk);

    return 0;
}

static void repl() {
    char line[1024];
    for (;;) {
        printf("> ");
        if (!fgets(line, sizeof(line), stdin)) {
            printf("\n");
            break;
        }
        interpret(line);
    }
}

static void runFile(const char* path){
    char* source = readFile(path);
    InterpretResult result = interpret(source);
    free(source);

    if (result ==  INTERPRET_COMPILE_ERROR) exit(65);
    if (result ==  INTERPRET_RUNTIME_ERROR) exit(65);
}

static char* readFile(const char* path) {
    FILE* file = fopen(path, "rb");

    if (file == NULL) {
        fprintf(stderr, "Could not open file \"%s\".\n", path);
        exit(74);
    }

    fseek(file, 0l, SEEK_END);
    size_t file_size = ftell(file);
    rewind(file);

    char* buffer = (char*)malloc(file_size + 1);
    if (buffer == NULL) {
        fprintf(stderr, "Not enough memory to read \"%s\".\n", path);
        exit(74);
    }
    size_t bytes_read = fread(buffer, sizeof(char), file_size, file);
    buffer[bytes_read] = '\0';

    if(bytes_read < file_size) {
        fprintf(stderr, "Could not read file \"%s\".\n", path);
        exit(74);
    }

    fclose(file);
    return buffer;
}
