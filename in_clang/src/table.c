#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "memory.h"
#include "object.h"
#include "table.h"
#include "value.h"

#define TABLE_MAX_LOAD 0.75

static Entry* Table_findEntry(Entry* entries, int capacity, ObjString* key);
static void Table_adjustCapacity(Table* table, int capacity);

void Table_init(Table* table) {
    table->count = 0;
    table->capacity = 0;
    table->entries = NULL;
}

void Table_free(Table* table) { FREE_ARRAY(Entry, table->entries, table->capacity); }

bool Table_set(Table* table, ObjString* key, Value value) {
    if (table->count + 1 > table->capacity * TABLE_MAX_LOAD) {
        int capacity = GROW_CAPACITY(table->capacity);
        Table_adjustCapacity(table, capacity);
    }

    Entry* entry = Table_findEntry(table->entries, table->capacity, key);
    bool isNewKey = entry->key == NULL;
    if (isNewKey && IS_NIL(entry->value)) {
        table->count++;
    }
    entry->key = key;
    entry->value = value;
    return isNewKey;
}

static Entry* Table_findEntry(Entry* entries, int capacity, ObjString* key) {
    uint32_t index = key->hash % capacity;
    Entry* tombstone = NULL;
    for (;;) {
        Entry* entry = &entries[index];

        if (entry->key == NULL) {
            if (IS_NIL(entry->value)) {
                return tombstone != NULL ? tombstone : entry;
            } else {
                if (tombstone == NULL)
                    tombstone = entry;
            }
        } else if (entry->key == key) {
            return entry;
        }
        index = (index + 1) % capacity;
    }
}

static void Table_adjustCapacity(Table* table, int new_capacity) {
    Entry* entries = ALLOCATE(Entry, new_capacity);
    table->count = 0;
    for (int i = 0; i < new_capacity; i++) {
        entries[i].key = NULL;
        entries[i].value = NIL_VAL;
    }
    int old_capacity = table->capacity;

    for (int i = 0; i < old_capacity; i++) {
        Entry* entry = &table->entries[i];
        if (entry->key == NULL)
            continue;
        Entry* dest = Table_findEntry(entries, new_capacity, entry->key);
        dest->key = entry->key;
        dest->value = entry->value;
        table->count++;
    }

    table->entries = entries;
    table->capacity = new_capacity;
}

void Table_addAll(Table* from, Table* to) {
    for (int i = 0; i < from->capacity; i++) {
        Entry* entry = &from->entries[i];
        if (entry->key == NULL)
            continue;
        Table_set(to, entry->key, entry->value);
    }
}

bool Table_get(Table* table, ObjString* key, Value* value) {
    if (table->count == 0)
        return false;
    Entry* entry = Table_findEntry(table->entries, table->capacity, key);
    if (entry->key == NULL)
        return false;
    *value = entry->value;
    return true;
}

bool Table_delete(Table* table, ObjString* key) {
    if (table->count == 0)
        return false;

    Entry* entry = Table_findEntry(table->entries, table->capacity, key);
    if (entry->key == NULL)
        return false;

    // Tombstore
    entry->key = NULL;
    entry->value = NIL_VAL;
    // table->count--;
    return true;
}

ObjString* Table_findString(Table* table, const char* chars, int length, uint32_t hash) {
    if (table->count == 0)
        return NULL;
    uint32_t index = hash % table->capacity;
    for (;;) {
        Entry* entry = &table->entries[index];
        if (entry->key == NULL) {
            if (IS_NIL(entry->value))
                return NULL;
        } else if (entry->key->length == length && entry->key->hash == hash &&
                   memcmp(entry->key->chars, chars, length) == 0) {
            return entry->key;
        }
        index = (index + 1) % table->capacity;
    }
}
