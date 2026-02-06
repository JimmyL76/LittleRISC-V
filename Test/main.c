// MMIO addr range: 0x0000_8000 to 0x0000_8FFF (high bit 15)
#define LEDS (*((volatile int*)0x00008000)) 
#define SEG_REG (*((volatile int*)0x00008004)) 
#define UART_STATUS (*((volatile int*)0x00008008)) 
#define UART_DATA   (*((volatile int*)0x0000800C)) 

void delay(int count) {
    while(count--) __asm volatile("nop");
}

void led() {
    int val = 1;
    int dir = 0; // 0 = left, 1 = right
    
    while(1) {
        LEDS = val;
        delay(100000); 
        
        if (dir == 0) {
            val = val << 1;
            if (val >= 0x8000) dir = 1; 
        } else {
            val = val >> 1;
            if (val <= 1) dir = 0; 
        }
    }
}

void led_test() {
    int val = 1;
    int dir = 0; // 0 = left, 1 = right
    
    while(1) {
        LEDS = val;
        // delay(100000); 
        
        if (dir == 0) {
            val = val << 1;
            if (val >= 0x8000) dir = 1; 
        } else {
            val = val >> 1;
            if (val <= 1) dir = 0; 
        }
    }
}

void seg() {
    char segments[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
    int i = 0;
    while(1) {
        SEG_REG = segments[i];
        delay(500000);
        i++;
        if (i > 15) i = 0;
    }
}

void fibonacci() {
    int a = 0;
    int b = 1;
    int temp;
    
    while(1) {
        LEDS = b;
        delay(500000);
        
        // tests forwarding logic with dependent instrs
        temp = a + b;
        a = b;
        b = temp;
        
        // Reset if it overflows 16 bits
        if (b > 65535) { 
            a = 0; 
            b = 1; 
        }
    }
}

int factorial(int n) {
    if (n <= 1) return 1;
    // CPU should save n and return addr to stack before jumping again
    return n * factorial(n - 1);
}

void recursive() {
    int result = factorial(5); // 5! = 120
    LEDS = result;
    while(1);
}

void UART() {
    char c;
    while(1) {
        // poll until rx_valid is 1
        while ((UART_STATUS & 1) == 0); 
        
        c = UART_DATA;
        LEDS = c;
        
        // echo after tx_busy is 0
        while ((UART_STATUS & 2) != 0);
        UART_DATA = c;
    }
}

int add_test() {
    __asm volatile ("addi x1, x0, 0");

    while(1) {
        __asm volatile ("addi x1, x1, 1");
    }

    return 0;
}

void main() {
    // led();
    led_test();
    // seg();
    // fibonacci();
    // recursive();
    // UART();
    // add_test();
}