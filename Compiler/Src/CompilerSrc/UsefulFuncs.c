//
// Created by Сергей Слепышев on 07.08.2023.
//

#include "UsefulFuncs.h"
#include <stdlib.h>
#include <ctype.h>
#include <memory.h>

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

///Сравнивает обычную строку и строку из стека index
int compareStrStack(const int a[], unsigned size, Stack* ptrStack, u_int32_t index){
    int j = 0;
    dStack_r(ptrStack, index);
    unsigned dStackSize = getSizeOfUnit_dStack(ptrStack);
    int *buff = malloc(dStackSize);
    memcpy(buff, dStack_r(ptrStack, index), dStackSize);
    for(j = 0; a[j] != '\0' && buff[j] != '\0' && a[j] == buff[j]
        && j < dStackSize && j < size; j++)
        ;
    if(a[j] == '\0' && buff[j] == '\0') {
        free(buff);
        return 1;
    }
    free(buff);
    return 0;
}

///Смотрит по массиву есть ли данная "op" в списке и возвращает ее индекс, иначе возвращает NONE
int searchFor(Stack *ptrNames, int op[], unsigned size){
    unsigned dStackSize = getsize_dStack(ptrNames);
    for(int i = 0; i < dStackSize; i++)
        if(compareStrStack(op, size, ptrNames, i)) return i;
    return NONE;
}