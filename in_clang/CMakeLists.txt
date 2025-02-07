cmake_minimum_required(VERSION 3.29)
project(clox C)

file(GLOB_RECURSE SOURCE_FILES src/*.c src/*.h)

set(CMAKE_C_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_BUILD_TYPE Debug)

# https://developer.apple.com/library/archive/documentation/Performance/Conceptual/ManagingMemory/Articles/MallocDebug.html
# Add debug symbols and enable address sanitizer
#set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g -fsanitize=address")
#set(CMAKE_LINKER_FLAGS_DEBUG "${CMAKE_LINKER_FLAGS_DEBUG} -fsanitize=address")

add_compile_options(-Wall -Wextra -Werror -fno-omit-frame-pointer -fsanitize=address)
add_link_options(-fsanitize=address)

add_executable(clox ${SOURCE_FILES})
# add_executable(clox main.c
#         chunk.h chunk.c
#         common.h
#         compiler.h compiler.c
#         debug.h debug.c
#         memory.h memory.c
#         object.h object.c
#         scanner.h scanner.c
#         value.c value.h
#         vm.h vm.c
# )
