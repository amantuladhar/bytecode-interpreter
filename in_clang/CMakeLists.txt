cmake_minimum_required(VERSION 3.29)
project(clox C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_BUILD_TYPE Debug)
add_compile_options(-Wall)

add_executable(clox main.c
    chunk.h chunk.c
    common.h
    compiler.h compiler.c
    debug.h debug.c
    memory.h memory.c
    object.h object.c
    scanner.h scanner.c
    value.c value.h
    vm.h vm.c
)
