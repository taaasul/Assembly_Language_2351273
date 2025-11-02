#include <stdio.h>

// 函数声明
int calculateSum(int n);
void testDifferentStorage();

int main() {
    int num;
    int sum;
    
    printf("=== 任务1：演示结果存储在不同位置 ===\n");
    testDifferentStorage();
    
    printf("\n=== 任务2：用户输入求和 ===\n");
    
    // 输入验证循环
    do {
        printf("Please enter a number (1-100): ");
        scanf("%d", &num);
        
        if (num < 1 || num > 100) {
            printf("Input error! Please enter 1-100.\n");
        }
    } while (num < 1 || num > 100);
    
    // 计算求和
    sum = calculateSum(num);
    
    // 输出结果（十进制）
    printf("Sum = %d\n", sum);
    
    return 0;
}

/**
 * 计算从1到n的和
 * @param n 上限值
 * @return 求和结果
 */
int calculateSum(int n) {
    int sum = 0;  // 存储在局部变量（类似寄存器）
    int i;
    
    // 循环累加：1 + 2 + 3 + ... + n
    for (i = 1; i <= n; i++) {
        sum += i;  // sum = sum + i
    }
    
    return sum;
}

/**
 * 演示结果存储在不同位置的情况
 * 对应汇编任务1的三种存储方式
 */
void testDifferentStorage() {
    // 方式1：存储在局部变量（类似寄存器）
    int sum_register = 0;
    for (int i = 1; i <= 100; i++) {
        sum_register += i;
    }
    printf("结果存在局部变量（类似寄存器）: %d\n", sum_register);
    
    // 方式2：存储在全局变量（类似数据段）
    static int sum_memory = 0;  // static变量存储在数据段
    for (int i = 1; i <= 100; i++) {
        sum_memory += i;
    }
    printf("结果存在静态变量（类似内存数据段）: %d\n", sum_memory);
    
    // 方式3：存储在动态分配的内存（类似栈）
    int *sum_stack = (int*)malloc(sizeof(int));  // 在堆上分配
    *sum_stack = 0;
    for (int i = 1; i <= 100; i++) {
        (*sum_stack) += i;
    }
    printf("结果存在动态分配内存（类似栈）: %d\n", *sum_stack);
    free(sum_stack);  // 释放内存
}