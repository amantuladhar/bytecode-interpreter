#include <stdio.h>

#include "chunk.h"

int main(int argc, const char* argv[]) {

    printf("-- PROGRAM STARTED --\n");
    printf("------------------\n\n");
    
    Chunk chunk;

    initChunk(&chunk);

    writeChunk(&chunk, OP_RETURN);

    freeChunk(&chunk);

    printf("\n\n------------------\n");
    printf("-- PROGRAM ENDED--\n");
    return 0;
}
