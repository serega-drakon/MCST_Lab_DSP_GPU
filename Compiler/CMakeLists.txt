cmake_minimum_required(VERSION 3.25)
project(MCST_Lab_DSP_GPU C)

set(CMAKE_C_STANDARD 11)

add_executable(MCST_Lab_DSP_GPU
        main.c
        Memory/sStack.c
        Memory/dStack.c
        Memory/sStack.h
        Memory/dStack.h
        Compiler/Compiler.h
        Compiler/Compiler.c)
