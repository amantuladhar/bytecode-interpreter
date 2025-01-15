#ifndef clox_vm_h
#define clox_vm_h

#include "chunk.h"
#include "value.h"


#define STACK_MAX 256

typedef enum {
    INTERPRET_OK,
    INTERPRET_COMPILE_ERROR,
    INTERPRET_RUNTIME_ERROR,
} InterpretResult;

typedef struct {
    Chunk* chunk;
    uint8_t* ip;
    Value stack[STACK_MAX];
    Value* stack_top;
} VM;

void VM_init();
void VM_free();
void VM_push(Value value);
Value VM_pop();
InterpretResult VM_interpret(Chunk* chunk);

#endif
