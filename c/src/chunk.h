#ifndef clox_chunk_h
#define clox_chunk_h

#include "common.h"
#include "value.h"

typedef enum {
    OP_CONSTANT,
    OP_RETURN,
} Chunk_OpCode;

typedef struct {
    int count;
    int capacity;
    uint8_t* code;
    ValueArray constants;
} Chunk;

void Chunk_init(Chunk* chunk);
void Chunk_write(Chunk* chunk, uint8_t byte);
void Chunk_free(Chunk* chunk);
int Chunk_addConstant(Chunk* chunk, Value value);

#endif
