
#ifndef clox_chunk_h
#define clox_chunk_h

#include "common.h"
#include "value.h"

typedef enum {
    OP_CONSTANT,
    OP_NIL,
    OP_TRUE,
    OP_FALSE,
    OP_ADD,
    OP_SUBTRACT,
    OP_MULTIPLY,
    OP_DIVIDE,
    OP_NOT,
    OP_NEGATE,
    OP_RETURN,
    OP_EQUAL,
    OP_GREATER,
    OP_LESS,
} OpCode;

typedef struct {
    uint8_t* code;
    int* lines;
    ValueArray constants;

    int count;
    int capacity;
} Chunk;

void Chunk_init(Chunk* chunk);
void Chunk_free(Chunk* chunk);
void Chunk_write(Chunk* chunk, uint8_t byte, int line);
int Chunk_addConstant(Chunk* chunk, Value value);

#endif
