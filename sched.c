
#define PAGE_SIZE 4096
long user_stack [ PAGE_SIZE>>2 ] ;
//stack_start 會使用lss指令載入，這樣會讓 esp=&user_stack, SS=0x10
struct
{
	long * a;
	short b;
} stack_start = { & user_stack [PAGE_SIZE>>2] , 0x10 };


