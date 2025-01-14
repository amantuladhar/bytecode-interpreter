#include <stdint.h>
#include <stdlib.h>

#include "chunk.h"
#include "memory.h"
#include "value.h"

void Chunk_init(Chunk* chunk) {
    chunk->count = 0;
    chunk->capacity = 0;
    chunk->code = NULL;
    ValueArray_init(&chunk->constants);
}

void Chunk_write(Chunk* chunk, uint8_t byte) {
    if (chunk->capacity < chunk->count + 1) {
        int old_capacity = chunk->capacity;
        chunk->capacity = GROW_CAPACITY(old_capacity);
        chunk->code = GROW_ARRAY(uint8_t, chunk->code, old_capacity, chunk->capacity);
    }
    chunk->code[chunk->count] = byte;
    chunk->count++;
}

void Chunk_free(Chunk* chunk) {
    FREE_ARRAY(uint8_t, chunk->code, chunk->capacity);
    ValueArray_free(&chunk->constants);
    Chunk_init(chunk);
}

int Chunk_addConstant(Chunk* chunk, Value value) {
    ValueArray_write(&chunk->constants, value);
    return chunk->constants.count - 1;
}
