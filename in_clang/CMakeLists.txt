cmake_minimum_required(VERSION 3.29)
project(clox C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_BUILD_TYPE Debug)

add_executable(clox main.c
    common.h debug.h debug.c chunk.h chunk.c memory.h memory.c
    value.c value.h vm.h vm.c
    compiler.h compiler.c
    scanner.h scanner.c
)
