
int main() {
    __asm__ volatile ("addi x1, x0, 0");

    while(1) {
        __asm__ volatile ("addi x1, x1, 1");

        // delay loop to not overflow x1 instantly
        for (volatile int i = 0; i < 50000; i++);
    }

    return 0;
}