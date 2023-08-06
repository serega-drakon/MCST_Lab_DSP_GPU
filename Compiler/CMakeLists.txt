cmake_minimum_required(VERSION 3.25)
project(dsp_gpu_compiler C)

set(CMAKE_C_STANDARD 11)

add_executable(main.c
        Src/dStack.c
        Inc/dStack.h
        Inc/Compiler.h
        Src/Compiler.c
        main.c)