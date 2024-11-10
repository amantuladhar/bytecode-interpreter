#include <stdio.h>
#include <string.h>

#include "memory.h"
#include "object.h"
#include "value.h"

void ValueArray_init(ValueArray* array) {
    array->values = NULL;
    array->capacity = 0;
    array->count = 0;
}

void ValueArray_write(ValueArray* array, Value value) {
    if (array->count >= array->capacity) {
        int old_capacity = array->capacity;
        array->capacity = GROW_CAPACITY(old_capacity);
        array->values = GROW_ARRAY(Value, array->values, old_capacity, array->capacity);
    }
    array->values[array->count++] = value;
}

void ValueArray_free(ValueArray* array) {
    FREE_ARRAY(Value, array->values, array->capacity);
    ValueArray_init(array);
}

void Value_printValue(const Value value) {
    switch (value.type) {
        case VAL_BOOL: printf(AS_BOOL(value) ? "true" : "false"); break;
        case VAL_NIL: printf("nil"); break;
        case VAL_NUMBER: printf("%g", AS_NUMBER(value)); break;
        case VAL_OBJ: printObject(value); break;
    }
}

bool Value_equal(Value a, Value b) {
    if (a.type != b.type) return false;
    switch (a.type) {
        case VAL_BOOL: return AS_BOOL(a) == AS_BOOL(b);
        case VAL_NUMBER: return AS_NUMBER(a) == AS_NUMBER(b);
        case VAL_NIL: return true;
        case VAL_OBJ: {
            ObjString* aStr = AS_STRING(a);
            ObjString* bStr = AS_STRING(b);
            return aStr->length == bStr->length && memcmp(aStr->chars, bStr->chars, aStr->length) == 0;
        }
    }
}
