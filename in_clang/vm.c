#include <stdio.h>

#include "chunk.h"
#include "common.h"
#include "compiler.h"
#include "debug.h"
#include "value.h"
#include "vm.h"

static InterpretResult run();
static void resetStack();

VM vm;

void initVM() {
    resetStack();
}

void freeVM() {}

void push(Value value) {
    *vm.stackTop = value;
    vm.stackTop++;
}

Value pop() {
    vm.stackTop--;
    return *vm.stackTop;
}

InterpretResult interpret(const char* source) {
    Chunk chunk;
    Chunk_init(&chunk);

    if (!Compiler_compile(source, &chunk)) {
        Chunk_free(&chunk);
        return INTERPRET_COMPILE_ERROR;
    }

    vm.chunk = &chunk;
    vm.ip = vm.chunk->code;

    const InterpretResult result = run();
    Chunk_free(&chunk);

    return result;
}

static InterpretResult run() {
#define READ_BYTE() (*vm.ip++)
#define READ_CONSTANT() (vm.chunk->constants.values[READ_BYTE()])
#define BINARY_OP(op)                                                                                                  \
    do {                                                                                                               \
        double b = pop();                                                                                              \
        double a = pop();                                                                                              \
        push(a op b);                                                                                                  \
    } while (false)

    for (;;) {

#ifdef DEBUG_TRACE_EXECUTION
        printf("%-8s", "");
        for (Value* slot = vm.stack; slot < vm.stackTop; slot++) {
            printf("[ ");
            Value_printValue(*slot);
            printf(" ]");
        }
        printf("\n");
        disassembleInstruction(vm.chunk, (int)(vm.ip - vm.chunk->code));
#endif

        uint8_t instruction;
        switch (instruction = READ_BYTE()) {
            case OP_CONSTANT: {
                Value constant = READ_CONSTANT();
                push(constant);
                break;
            }
            case OP_ADD: BINARY_OP(+); break;
            case OP_SUBTRACT: BINARY_OP(-); break;
            case OP_MULTIPLY: BINARY_OP(*); break;
            case OP_DIVIDE: BINARY_OP(/); break;
            case OP_NEGATE: {
                push(-pop());
                break;
            }
            case OP_RETURN: {
                Value_printValue(pop());
                printf("\n");
                return INTERPRET_OK;
            }
        }
    }

#undef READ_CONSTANT
#undef READ_BYTE
#undef BINARY_OP
}

static void resetStack() {
    vm.stackTop = vm.stack;
}
