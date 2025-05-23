#include <stdlib.h>

#include "memory.h"
#include "object.h"
#include "value.h"
#include "vm.h"

void* reallocate(void* pointer, size_t old_size, size_t new_size) {
    (void) old_size;
    if (new_size == 0) {
        free(pointer);
        return NULL;
    }
    void* result = realloc(pointer, new_size);
    if (result == NULL) exit(1);
    return result;
}

void freeObject(Obj* object) {
    switch (object->type) {
        case OBJ_STRING: {
            ObjString* string = (ObjString*)object;
            FREE_ARRAY(char, string->chars, string->length + 1);
            FREE(ObjString, object);
            break;
        };
    }
}

void freeObjects() {
    Obj* object = vm.objects;
    while (object != NULL) {
        Obj* next = object->next;
        freeObject(object);
        object = next;
    }
}
