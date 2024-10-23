

#include <stdlib.h>

#include "memory.h"
#include "chunk.h"

void initChunk(Chunk *chunk) {
    chunk->count = 0;
    chunk->capacity = 0;
    chunk->code = NULL;
}

void freeChunk(Chunk *chunk) {
    FREE_ARRAY(uint8_t, chunk->code, chunk->capacity);
    initChunk(chunk);
}

void writeChunk(Chunk* chunk, uint8_t byte) {
    if (chunk->count >= chunk->capacity) {
        int old_capacity = chunk->capacity;
        chunk->capacity = GROW_CAPACITY(old_capacity);
        chunk->code = GROW_ARRAY(uint8_t, chunk->code, old_capacity, chunk->capacity);
    }
    chunk->code[chunk->count] = byte;
    chunk->count++;
}
