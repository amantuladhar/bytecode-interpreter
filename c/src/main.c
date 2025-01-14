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
    Chunk_write(&chunk, OP_CONSTANT);
    Chunk_write(&chunk, constant);

    constant = Chunk_addConstant(&chunk, 2.9);
    Chunk_write(&chunk, OP_CONSTANT);
    Chunk_write(&chunk, constant);

    Chunk_write(&chunk, OP_RETURN);
    disassembleChunk(&chunk, "test chunk");
    Chunk_free(&chunk);

    return 0;
}
