#ifndef clox_compiler_h
#define clox_compiler_h

#include "chunk.h"
#include "object.h"

bool Compiler_compile(const char* source, Chunk* chunk);

#endif
