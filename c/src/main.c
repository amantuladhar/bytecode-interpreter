#include <stdio.h>

#include "chunk.h"
#include "common.h"
#include "debug.h"

int main(int argc, char** argv) {
    (void)argc;
    (void)argv[0];

    Chunk chunk;
    Chunk_init(&chunk);

    int constant = Chunk_addConstant(&chunk, 1.2);
    Chunk_write(&chunk, OP_CONSTANT, 123);
    Chunk_write(&chunk, constant, 123);

    constant = Chunk_addConstant(&chunk, 2.9);
    Chunk_write(&chunk, OP_CONSTANT, 123);
    Chunk_write(&chunk, constant, 123);

    Chunk_write(&chunk, OP_RETURN, 123);
    disassembleChunk(&chunk, "test chunk");
    Chunk_free(&chunk);

    return 0;
}
