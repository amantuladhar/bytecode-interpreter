#include <stdlib.h>

#include "chunk.h"
#include "memory.h"
#include "value.h"

void Chunk_init(Chunk *chunk) {
    chunk->count = 0;
    chunk->capacity = 0;
    chunk->code = NULL;
    chunk->lines = NULL;
    ValueArray_init(&chunk->constants);
}

void Chunk_free(Chunk *chunk) {
    ValueArray_free(&chunk->constants);
    FREE_ARRAY(uint8_t, chunk->code, chunk->capacity);
    FREE_ARRAY(uint8_t, chunk->lines, chunk->capacity);
    Chunk_init(chunk);
}

void Chunk_write(Chunk *chunk, uint8_t byte, int line) {
    if (chunk->count >= chunk->capacity) {
        int old_capacity = chunk->capacity;
        chunk->capacity = GROW_CAPACITY(old_capacity);
        chunk->code =
            GROW_ARRAY(uint8_t, chunk->code, old_capacity, chunk->capacity);
        chunk->lines =
            GROW_ARRAY(int, chunk->lines, old_capacity, chunk->capacity);
    }
    chunk->code[chunk->count] = byte;
    chunk->lines[chunk->count] = line;
    chunk->count++;
}

int Chunk_addConstant(Chunk *chunk, Value value) {
    ValueArray_write(&chunk->constants, value);
    return chunk->constants.count - 1;
}
