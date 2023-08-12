#include "dStack.h"
#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <assert.h>

#define KAN_NUM 1
#define KAN_VALUE 255    //1111.1111
#define POISON_VALUE 255 //1111.1111

#define EXIT_MAIN do{ \
printf("Stack error");\
if (error_main_read(ptrStack, BuffForErrNull) == 0)\
    return ptrStack->buffForErr;                    \
else                                                \
    return NULL;                                    \
}while(0)

#define EXIT do{ \
if (ptrStack != NULL && error_main_read(ptrStack, BuffForErrNull) == 0)\
    return ptrStack->buffForErr;                    \
else                                                \
    return NULL;                                    \
}while(0)

typedef enum Errors_ { //Не больше 8 ошибок! иначе надо расширять переменную error
    PtrStackNull = 0, //number of right bit in error
    DataArrayNull,
    BuffForErrNull,
    BuffForResNull,
    MetaNull,
    KanareiykePizda,
} Errors;

/// Structure of stack
struct Stack_ {
    void *ptrData; ///< Pointer to ptrData
    void *buffForErr;///< buffForErr returns if error occurred
    void *buffForRes;///< buffForRes points to result of stack_main() func
    void *buffForPop;///< buffer for pop_dStack func
    u_int32_t sizeOfUnit; ///< Size of one element of ptrData in bytes
    u_int32_t num; ///< Number of elements of ptrData (malloced memory)
    u_int32_t pos; ///< Next free position of stack (pop_dStack/push_dStack/getlast)
    u_int8_t *meta; ///< "Poison" check of ptrData

    u_int32_t metaNum; ///< Number of elements of meta (malloced memory)
    u_int8_t error;///< is an array of bools
};

int error_main_read(Stack *ptrStack, Errors numOfError);
int error_main_write(Stack *ptrStack, Errors numOfError);

void stack_extend(Stack *ptrStack, u_int32_t x);

int meta_main_read(Stack *ptrStack, u_int32_t x);
int meta_main_has_used(Stack *ptrStack, u_int32_t x);
int meta_main_reset(Stack *ptrStack, u_int32_t x);

int kanareiyka_check(Stack *ptrStack);

void saveResToBuff(Stack *ptrStack, u_int32_t x){
    const u_int32_t shift_in_stack = (x + KAN_NUM) * ptrStack->sizeOfUnit;
    const void* from_buf = &((char *) ptrStack->ptrData)[shift_in_stack];
    memcpy(ptrStack->buffForRes, from_buf, ptrStack->sizeOfUnit);
}

void *stack_main_write(Stack *ptrStack, u_int32_t x, const void *ptrValue){
    assert(ptrStack != NULL);
    assert(ptrValue != NULL);
    assert(x >= 0);

    if(kanareiyka_check(ptrStack))
        error_main_write(ptrStack, KanareiykePizda);
    if(dStackErrorCheck(ptrStack)) {
        dStackErrorPrint(ptrStack);
        EXIT_MAIN;
    }
    //extend check
    stack_extend(ptrStack, x);
    if (dStackErrorCheck(ptrStack)) {
        printf("stack_main: error\n");
        dStackErrorPrint(ptrStack);
        EXIT_MAIN;
    }

    memcpy(&(((char *) ptrStack->ptrData)[(x + KAN_NUM) * ptrStack->sizeOfUnit]), ptrValue, ptrStack->sizeOfUnit);
    meta_main_has_used(ptrStack, x);
    saveResToBuff(ptrStack, x);
    return ptrStack->buffForRes;
}

void *stack_main_read(Stack *ptrStack, u_int32_t x){
    assert(ptrStack != NULL);
    assert(x >= 0);

    if(kanareiyka_check(ptrStack))
        error_main_write(ptrStack, KanareiykePizda);
    if(dStackErrorCheck(ptrStack)) {
        dStackErrorPrint(ptrStack);
        EXIT_MAIN;
    }
    //extend check
    stack_extend(ptrStack, x);
    if (dStackErrorCheck(ptrStack)) {
        printf("stack_main: error\n");
        dStackErrorPrint(ptrStack);
        EXIT_MAIN;
    }
    //check here needed
    if (!meta_main_read(ptrStack, x))
        printf("stack_main: using before undefined value X = %d\n", x);
    saveResToBuff(ptrStack, x);
    return ptrStack->buffForRes;
}

/// Extends given Stack
void stack_extend(Stack *ptrStack, u_int32_t x) {
    assert(ptrStack != NULL);
    assert(x >= 0);

    void *previousPtr;

    //Сначала выделяем память под ptrData
    if (x >= ptrStack->num) {
        previousPtr = ptrStack->ptrData;
        x = x * 2; //new number of elements
        ptrStack->ptrData = malloc((x + 2 * KAN_NUM) * ptrStack->sizeOfUnit); //+канарейка слева и справа
        if (ptrStack->ptrData != NULL) {
            //возвращаем элементы (включил канарейку слева)
            //указатель на новую канарейку справа
            void *ptrKanRightNew = &((char*)ptrStack->ptrData)[(KAN_NUM + x) * ptrStack->sizeOfUnit];
            //указатель на старую канарейку справа
            void *ptrKanRightOld = &((char*)previousPtr)[(KAN_NUM + ptrStack->num) * ptrStack->sizeOfUnit];

            memcpy(ptrStack->ptrData, previousPtr, (KAN_NUM + ptrStack->num) * ptrStack->sizeOfUnit);
            memcpy(ptrKanRightNew, ptrKanRightOld, KAN_NUM * ptrStack->sizeOfUnit);

            if(!error_main_read(ptrStack, BuffForErrNull))
                //заполняю пустоты пойзонами
                for(int i = 0; i < (x - ptrStack->num) * ptrStack->sizeOfUnit ; i++){
                    ((unsigned char*)ptrStack->ptrData)[(KAN_NUM + ptrStack->num) * ptrStack->sizeOfUnit + i] = POISON_VALUE;
                }
            ptrStack->num = x;
            free(previousPtr);
        } else {
            error_main_write(ptrStack, DataArrayNull);
            ptrStack->ptrData = previousPtr;
            return;
        }
    }
    //Потом выделяем память для meta
    if (x > ptrStack->metaNum * 8) {
        previousPtr = ptrStack->meta;
        u_int32_t y;
        for(y = ptrStack->metaNum; y * 8 < x; y *= 2)
            ;
        ptrStack->meta = calloc(y, sizeof(char));
        if (ptrStack->meta != NULL) {
            //возвращаем элементы
            memcpy(ptrStack->meta, previousPtr, ptrStack->metaNum);
            ptrStack->metaNum = y;
            free(previousPtr);
        } else {
            error_main_write(ptrStack, MetaNull);
            ptrStack->meta = previousPtr;
            return;
        }
    }

}

///Битовый массив, который содержит информацию об использовании каждого из элементов массива
int meta_main_read(Stack *ptrStack, u_int32_t x){
    assert(ptrStack != NULL);
    //нумерация справа налево
    const int numOfBit = 7 - (char) (x % 8);
    return (ptrStack->meta[x / 8] >> numOfBit) & 1; //достаю нужный бит
}

///Битовый массив, который содержит информацию об использовании каждого из элементов массива
int meta_main_has_used(Stack *ptrStack, u_int32_t x){
    assert(ptrStack != NULL);
    //нумерация справа налево
    const int numOfBit = 7 - (char) (x % 8);
    ptrStack->meta[x / 8] = ptrStack->meta[x / 8] | (1 << numOfBit);
    return (ptrStack->meta[x / 8] >> numOfBit) & 1; //достаю нужный бит
}

///Битовый массив, который содержит информацию об использовании каждого из элементов массива
int meta_main_reset(Stack *ptrStack, u_int32_t x){
    assert(ptrStack != NULL);
    //нумерация справа налево
    const int numOfBit = 7 - (char) (x % 8);
    ptrStack->meta[x / 8] = ptrStack->meta[x / 8] & ~(1 << numOfBit);
    return (ptrStack->meta[x / 8] >> numOfBit) & 1; //достаю нужный бит
}

///Максимум вариантов ошибок - 8 с таким размером error.
int error_main_read(Stack *ptrStack, Errors numOfError){
    assert(ptrStack != NULL);
    assert(numOfError >= 0);
    return ptrStack->error >> numOfError & 1; //достаю нужный бит
}

///Максимум вариантов ошибок - 8 с таким размером error.
int error_main_write(Stack *ptrStack, Errors numOfError){
    assert(ptrStack != NULL);
    assert(numOfError >= 0);
    ptrStack->error = ptrStack->error | (1 << numOfError);
    return ptrStack->error >> numOfError & 1; //достаю нужный бит
}

///проверяет канарейки массива и возвращает 1 если они повреждены, 0 если нет.
int kanareiyka_check(Stack *ptrStack){
    int check = 0;
    const u_int32_t shift = (KAN_NUM + ptrStack->num) * ptrStack->sizeOfUnit;
    for(int i = 0; i < KAN_NUM * ptrStack->sizeOfUnit; i++)
        if(((unsigned char*)ptrStack->ptrData)[i] != KAN_VALUE
           || ((unsigned char*)ptrStack->ptrData)[shift + i] != KAN_VALUE)
            check = 1;
    return check;
}

///сбрасывает текущую позицию массива до пойзона.
void stack_reset_pos(Stack *ptrStack, u_int32_t x){
    u_int32_t i;
    for(i = 0; i < ptrStack->sizeOfUnit; i++)
        ((unsigned char*)ptrStack->buffForErr)[i] = POISON_VALUE;
    stack_main_write(ptrStack, x, ptrStack->buffForErr);
    meta_main_reset(ptrStack, ptrStack->pos);
    for(i = 0; i < ptrStack->sizeOfUnit; i++)
        ((char*)ptrStack->buffForErr)[i] = 0;
}

///returns !0 if error occurred
int dStackErrorCheck(Stack *ptrStack) {
    if (ptrStack != NULL) {
        return ptrStack->error;
    } else
        return 1 << PtrStackNull;
    //ака так бы было если бы переменная error существовала
}

///Выводит инфу об ошибках в консоль.
void dStackErrorPrint(Stack *ptrStack){
    if (ptrStack != NULL) {
        if (error_main_read(ptrStack, DataArrayNull))
            printf("error DataArrayNull\n");
        if (error_main_read(ptrStack, BuffForErrNull))
            printf("error BuffForErrNull\n");
        if (error_main_read(ptrStack, BuffForResNull))
            printf("error BuffForResNull\n");
        if (error_main_read(ptrStack, MetaNull))
            printf("error MetaNull\n");
        if(error_main_read(ptrStack, KanareiykePizda)){
            printf("error KanareiykePizda\n");
        }
    } else
        printf("error PtrStackNull\n");
}

/// Constructor of stack.
Stack *dStackInit(u_int32_t size) {
    if (size <= 0)
        return NULL;
    Stack *ptrStack;
    ptrStack = malloc(sizeof(Stack));
    if (ptrStack != NULL) {
        ptrStack->sizeOfUnit = size;
        ptrStack->pos = 0;
        ptrStack->metaNum = 0;
        ptrStack->error = 0;

        ptrStack->buffForRes = malloc(ptrStack->sizeOfUnit);
        if (ptrStack->buffForRes == NULL)
            error_main_write(ptrStack, BuffForResNull);
        ptrStack->buffForErr = calloc(1, ptrStack->sizeOfUnit);
        if (ptrStack->buffForErr == NULL)
            error_main_write(ptrStack, BuffForErrNull);
        ptrStack->buffForPop = malloc(ptrStack->sizeOfUnit);
        if (ptrStack->buffForPop == NULL)
            error_main_write(ptrStack, BuffForErrNull);
        ptrStack->meta = calloc(1, sizeof(char));
        ptrStack->metaNum = 1;
        if(ptrStack->meta == NULL)
            error_main_write(ptrStack, MetaNull);

        ptrStack->ptrData = malloc((2 * KAN_NUM + 1) * ptrStack->sizeOfUnit);
        if(ptrStack->ptrData != NULL) {    //заполняем канарейки
            ptrStack->num = 1;
            int i;
            const u_int32_t shift = (KAN_NUM + ptrStack->num) * ptrStack->sizeOfUnit;

            for(i = 0; i < KAN_NUM * ptrStack->sizeOfUnit; i++){
                ((unsigned char*)ptrStack->ptrData)[i] = KAN_VALUE;
                ((unsigned char*)ptrStack->ptrData)[shift + i] = KAN_VALUE;
            }
            for(i = 0; i < ptrStack->sizeOfUnit; i++)
                ((unsigned char*)ptrStack->ptrData)[KAN_NUM * ptrStack->sizeOfUnit + i]= POISON_VALUE;
        }
        else
            error_main_write(ptrStack, DataArrayNull);
    } else
        printf("dStackInit: memory error\n");
    return ptrStack;
}

/// Деструктор стека
void dStackFree(Stack *ptrStack){
    if(ptrStack != NULL){
        free(ptrStack->ptrData);
        free(ptrStack->buffForErr);
        free(ptrStack->buffForRes);
        free(ptrStack->buffForPop);
        free(ptrStack->meta);
    }
    free(ptrStack);
}

/// Array READ function
void *dStack_r(Stack *ptrStack, u_int32_t x) {
    if (!dStackErrorCheck(ptrStack))
        return stack_main_read(ptrStack, x);
    else
        EXIT;
}

/// Array WRITE function
void *dStack_w(Stack *ptrStack, u_int32_t x, const void *ptrValue) {
    if (!dStackErrorCheck(ptrStack) && ptrValue != NULL)
        return stack_main_write(ptrStack, x, ptrValue);
    else
        EXIT;
}

/// Stack function: Push
void *push_dStack(Stack *ptrStack, const void *ptrValue) {
    if (!dStackErrorCheck(ptrStack) && ptrValue != NULL)
        return stack_main_write(ptrStack, ptrStack->pos++, ptrValue);
    else
        EXIT;
}

/// Stack function: Pop
void *pop_dStack(Stack *ptrStack) {
    if (!dStackErrorCheck(ptrStack) && ptrStack->pos > 0) {
        --ptrStack->pos;
        memcpy(ptrStack->buffForPop, stack_main_read(ptrStack, ptrStack->pos), ptrStack->sizeOfUnit);
        stack_reset_pos(ptrStack, ptrStack->pos);
        return ptrStack->buffForPop;
    }
    else
        EXIT;
}

/// Stack function: GetLast
void *getLast_dStack(Stack *ptrStack) {
    if (!dStackErrorCheck(ptrStack) && ptrStack->pos > 0)
        return stack_main_read(ptrStack, ptrStack->pos - 1);
    else
        EXIT;
}

u_int32_t getsize_dStack(Stack *ptrStack){
    if(!dStackErrorCheck(ptrStack))
        return ptrStack->pos;
    else
        return 0;
}

/// попает все элементы
void dStackReset(Stack *ptrStack){
    //todo
}