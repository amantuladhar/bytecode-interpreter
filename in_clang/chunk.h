
#ifndef clox_chunk_h
#define clox_chunk_h

#include "common.h"
#include "value.h"

typedef enum {
    OP_CONSTANT,
    OP_ADD,
    OP_SUBTRACT,
    OP_MULTIPLY,
    OP_DIVIDE,
    OP_NEGATE,
    OP_RETURN,
} OpCode;

typedef struct {
    uint8_t *code;
    int *lines;
    ValueArray constants;

    int count;
    int capacity;
} Chunk;

void Chunk_init(Chunk *chunk);
void Chunk_free(Chunk *chunk);
void Chunk_write(Chunk *chunk, uint8_t byte, int line);
int Chunk_addConstant(Chunk *chunk, Value value);

#endif
