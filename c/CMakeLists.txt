cmake_minimum_required(VERSION 3.29)
project(clox C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_BUILD_TYPE Debug)

file(GLOB_RECURSE SOURCE_FILES src/*.c src/*.h)

add_executable(clox ${SOURCE_FILES})

# Add compiler flags only for your target
target_compile_options(clox PRIVATE
        -Wall
        -Wextra
        -Werror
        -fno-omit-frame-pointer
        -fsanitize=address
)
# Add linker flags only for your target
target_link_options(clox PRIVATE -fsanitize=address)
