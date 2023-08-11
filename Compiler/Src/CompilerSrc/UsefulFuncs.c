//
// Created by Сергей Слепышев on 07.08.2023.
//

#include "UsefulFuncs.h"
#include <stdlib.h>
#include <ctype.h>

///Сравнивает строки    \n
///Возвращет 1 если совпали, иначе - 0
int compareStrIntChar(const int a[], const char b[]){
    int j;
    int flag = 1;
    for(j = 0; flag && a[j] != '\0' && b[j] != '\0'; j++) {
        if (a[j] != b[j]) flag = 0;
    }
    if(flag && a[j] == '\0' && b[j] == '\0')
        return 1;
    return 0;
}

///Возвращает константу в 10-ной СС
u_int8_t getConst10D(const int op[]){
    u_int8_t value = 0;
    for(int i = 1; op[i] != '\0'; i++)
        value = value * 10 + op[i] - '0';
    return value;
}

///Возвращает константу в 16-ной СС
u_int8_t getConst16D(const int op[]){
    u_int8_t value = 0;
    for(int i = 1; op[i] != '\0'; i++)
        value = value * 16 + op[i] - (isdigit(op[i]) ? '0' : 'A' - 10);
    return value;
}

void putZeroes(void* dst, unsigned size){
    for(unsigned i = 0; i < size; i++)
        ((char*)dst)[i] = 0;
}