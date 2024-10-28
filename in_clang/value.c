#include <stdio.h>

#include "memory.h"
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

void Value_printValue(Value value) {
    printf("%g", value);
}
