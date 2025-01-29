#include <stdio.h>

#include "chunk.h"
#include "common.h"
#include "debug.h"
#include "value.h"
#include "vm.h"

static InterpretResult run();
static void resetStack();

VM vm;

void VM_init() {
    resetStack();
}

void VM_free() {}

void VM_push(Value value) {
    *vm.stack_top = value;
    vm.stack_top++;
}

Value VM_pop() {
    vm.stack_top--;
    return *vm.stack_top;
}

InterpretResult VM_interpret(const char* source) {
    compile(source);
    return INTERPRET_OK;
}

static InterpretResult run() {
#define READ_BYTE() (*vm.ip++)
#define READ_CONSTANT() (vm.chunk->constants.values[READ_BYTE()])
#define BINARY_OP(op)     \
    do {                  \
        double b = VM_pop(); \
        double a = VM_pop(); \
        VM_push(a op b);     \
    } while (false)

    for (;;) {
        // This is for more or less stacktrace
        /*#ifndef DEBUG_TRACE_EXECUTION*/
        printf("        ");
        for (Value* slot = vm.stack; slot < vm.stack_top; slot++) {
            printf("[");
            printValue(*slot);
            printf("]");
        }
        printf("\n");
        disassembleInstruction(vm.chunk, (int)(vm.ip - vm.chunk->code));
        /*#endif*/

        uint8_t instruction;
        switch (instruction = READ_BYTE()) {
            case OP_CONSTANT: {
                Value constant = READ_CONSTANT();
                VM_push(constant);
                break;
            }
            case OP_ADD: BINARY_OP(+); break;
            case OP_SUBTRACT: BINARY_OP(-); break;
            case OP_MULTIPLY: BINARY_OP(*); break;
            case OP_DIVIDE: BINARY_OP(/); break;
            case OP_NEGATE: VM_push(-VM_pop()); break;
            case OP_RETURN: {
                printValue(VM_pop());
                printf("\n");
                return INTERPRET_OK;
            }
        }
    }

#undef READ_BYTE
#undef READ_CONSTANT
#undef BINARY_OP
}

static void resetStack() {
    vm.stack_top = vm.stack;
}
