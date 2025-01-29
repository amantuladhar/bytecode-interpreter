#include <stdio.h>

#include "chunk.h"
#include "common.h"
#include "debug.h"
#include "vm.h"

int main(int argc, char** argv) {
    (void)argc;
    (void)argv[0];

    VM_init();

    Chunk chunk;
    Chunk_init(&chunk);

    int constant = Chunk_addConstant(&chunk, 1.2);
    Chunk_write(&chunk, OP_CONSTANT, 123);
    Chunk_write(&chunk, constant, 123);

    constant = Chunk_addConstant(&chunk, 2.8);
    Chunk_write(&chunk, OP_CONSTANT, 123);
    Chunk_write(&chunk, constant, 123);

    Chunk_write(&chunk, OP_ADD, 123);

    constant = Chunk_addConstant(&chunk, 2);
    Chunk_write(&chunk, OP_CONSTANT, 123);
    Chunk_write(&chunk, constant, 123);

    Chunk_write(&chunk, OP_DIVIDE, 123);

    Chunk_write(&chunk, OP_NEGATE, 123);

    Chunk_write(&chunk, OP_RETURN, 123);
    printf("\n\n======== Disassemble Chunk =============\n\n");
    disassembleChunk(&chunk, "test chunk");
    printf("\n==========================================\n");

    printf("\n\n======== Interpret =============\n\n");
    VM_interpret(&chunk);
    printf("\n==================================\n");

    VM_free();
    Chunk_free(&chunk);

    return 0;
}
