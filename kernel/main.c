/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 main.c
 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 Forrest Yu, 2005
 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "type.h"
#include "stdio.h"
#include "const.h"
#include "protect.h"
#include "string.h"
#include "fs.h"
#include "proc.h"
#include "tty.h"
#include "console.h"
#include "global.h"
#include "proto.h"

/*****************************************************************************
 *                               kernel_main
 *****************************************************************************/
/**
 * jmp from kernel.asm::_start. 
 * 
 *****************************************************************************/
PUBLIC int kernel_main()
{
    disp_str("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");

    int i, j, eflags, prio;
    u8 rpl;
    u8 priv; /* privilege */

    struct task * t;
    struct proc * p = proc_table;

    char * stk = task_stack + STACK_SIZE_TOTAL;

    for (i = 0; i < NR_TASKS + NR_PROCS; i++, p++, t++){
        if(i >= NR_TASKS + NR_NATIVE_PROCS){
            p->p_flags = FREE_SLOT;
            continue;
        }

        if(i < NR_TASKS){ /* TASK */
            t = task_table + i;
            priv = PRIVILEGE_TASK;
            rpl = RPL_TASK;
            eflags = 0x1202;/* IF=1, IOPL=1, bit 2 is always 1 */
            prio = 15;
        }
        else{ /* USER PROC */
            t = user_proc_table + (i - NR_TASKS);
            priv = PRIVILEGE_USER;
            rpl = RPL_USER;
            eflags = 0x202; /* IF=1, bit 2 is always 1 */
            prio = 5;
        }

        strcpy(p->name, t->name); /* name of the process */
        p->p_parent = NO_TASK;

        if(strcmp(t->name, "INIT") != 0){
            p->ldts[INDEX_LDT_C] = gdt[SELECTOR_KERNEL_CS >> 3];
            p->ldts[INDEX_LDT_RW] = gdt[SELECTOR_KERNEL_DS >> 3];

            /* change the DPLs */
            p->ldts[INDEX_LDT_C].attr1 = DA_C | priv << 5;
            p->ldts[INDEX_LDT_RW].attr1 = DA_DRW | priv << 5;
        }
        else{ /* INIT process */
            unsigned int k_base;
            unsigned int k_limit;
            int ret = get_kernel_map(&k_base, &k_limit);
            assert(ret == 0);
            init_desc(&p->ldts[INDEX_LDT_C],
                    0, /* bytes before the entry point
                     * are useless (wasted) for the
                     * INIT process, doesn't matter
                     */
                    (k_base + k_limit) >> LIMIT_4K_SHIFT,
                    DA_32 | DA_LIMIT_4K | DA_C | priv << 5);

            init_desc(&p->ldts[INDEX_LDT_RW],
                    0, /* bytes before the entry point
                     * are useless (wasted) for the
                     * INIT process, doesn't matter
                     */
                    (k_base + k_limit) >> LIMIT_4K_SHIFT,
                    DA_32 | DA_LIMIT_4K | DA_DRW | priv << 5);
        }

        p->regs.cs = INDEX_LDT_C << 3 | SA_TIL | rpl;
        p->regs.ds =
                p->regs.es =
                        p->regs.fs =
                                p->regs.ss = INDEX_LDT_RW << 3 | SA_TIL | rpl;
        p->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | rpl;
        p->regs.eip = (u32) t->initial_eip;
        p->regs.esp = (u32) stk;
        p->regs.eflags = eflags;

        p->ticks = p->priority = prio;

        p->p_flags = 0;
        p->p_msg = 0;
        p->p_recvfrom = NO_TASK;
        p->p_sendto = NO_TASK;
        p->has_int_msg = 0;
        p->q_sending = 0;
        p->next_sending = 0;

        for (j = 0; j < NR_FILES; j++)
            p->filp[j] = 0;

        stk -= t->stacksize;
    }

    k_reenter = 0;
    m_ticks = 0;

    p_proc_ready = proc_table;

    init_clock();
    init_keyboard();

    restart();

    while( 1 ){
    }
}

/*****************************************************************************
 *                                get_ticks
 *****************************************************************************/
PUBLIC int get_ticks()
{
    MESSAGE msg;
    reset_msg(&msg);
    msg.type = GET_TICKS;
    send_recv(BOTH, TASK_SYS, &msg);
    return msg.RETVAL;
}

/*****************************************************************************
 *                                Init
 *****************************************************************************/
/**
 * The hen.
 * 
 *****************************************************************************/
void Init()
{
    int fd_stdin = open("/dev_tty0", O_RDWR);
    assert(fd_stdin == 0);
    int fd_stdout = open("/dev_tty0", O_RDWR);
    assert(fd_stdout == 1);

    printf("Init() is running ...\n");

    int pid = fork();
    if(pid != 0){ /* parent process */
        printf("parent is running, child pid:%d\n", pid);
        spin("parent");
    }
    else{ /* child process */
        printf("child is running, pid:%d\n", getpid());
        spin("child");
    }
}

/*======================================================================*
 TestA
 *======================================================================*/
void TestA()
{
    int fd;
    int i, n;

    char filename[MAX_FILENAME_LEN + 1] = "blah";
    const char bufw[] = "abcde";
    const int rd_bytes = 3;
    char bufr[rd_bytes];

    assert(rd_bytes <= strlen((char* )bufw));

    /* create */
    fd = open(filename, O_CREAT | O_RDWR);
    assert(fd != -1);
    printf("File created: %s (fd %d)\n", filename, fd);

    /* write */
    n = write(fd, bufw, strlen((char*) bufw));
    assert(n == strlen((char* )bufw));

    /* close */
    close(fd);

    /* open */
    fd = open(filename, O_RDWR);
    assert(fd != -1);
    printf("File opened. fd: %d\n", fd);

    /* read */
    n = read(fd, bufr, rd_bytes);
    assert(n == rd_bytes);
    bufr[n] = 0;
    printf("%d bytes read: %s\n", n, bufr);

    /* close */
    close(fd);

    char * filenames[] = { "/foo", "/bar", "/baz" };

    /* create files */
    for (i = 0; i < sizeof(filenames) / sizeof(filenames[0]); i++){
        fd = open(filenames[i], O_CREAT | O_RDWR);
        assert(fd != -1);
        printf("File created: %s (fd %d)\n", filenames[i], fd);
        close(fd);
    }

    char * rfilenames[] = { "/bar", "/foo", "/baz", "/dev_tty0" };

    /* remove files */
    for (i = 0; i < sizeof(rfilenames) / sizeof(rfilenames[0]); i++){
        if(unlink(rfilenames[i]) == 0)
            printf("File removed: %s\n", rfilenames[i]);
        else
            printf("Failed to remove file: %s\n", rfilenames[i]);
    }

    spin("TestA");
}

/*======================================================================*
 TestB
 *======================================================================*/
void TestB()
{
    char tty_name[] = "/dev_tty1";

    int fd_stdin = open(tty_name, O_RDWR);
    assert(fd_stdin == 0);
    int fd_stdout = open(tty_name, O_RDWR);
    assert(fd_stdout == 1);

    char rdbuf[128];

    while( 1 ){
        write(fd_stdout, "$ ", 2);
        int r = read(fd_stdin, rdbuf, 70);
        rdbuf[r] = 0;

        if(strcmp(rdbuf, "hello") == 0){
            write(fd_stdout, "hello world!\n", 13);
        }
        else{
            if(rdbuf[0]){
                write(fd_stdout, "{", 1);
                write(fd_stdout, rdbuf, r);
                write(fd_stdout, "}\n", 2);
            }
        }
    }

    assert(0); /* never arrive here */
}

/*======================================================================*
 TestB
 *======================================================================*/
void TestC()
{
    //spin("TestC");
    /* assert(0); */
    while( 1 ){
        printf("C");
        milli_delay(200);
    }
}

/*****************************************************************************
 *                                panic
 *****************************************************************************/
PUBLIC void panic(const char *fmt, ...)
{
    int i;
    char buf[256];

    /* 4 is the size of fmt in the stack */
    va_list arg = (va_list) ((char*) &fmt + 4);

    i = vsprintf(buf, fmt, arg);

    printl("%c !!panic!! %s", MAG_CH_PANIC, buf);

    /* should never arrive here */
    __asm__ __volatile__("ud2");
}

