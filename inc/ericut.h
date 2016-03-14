#ifndef _UT_ERIC_H_
#define _UT_ERIC_H_

void ut_start(void);
void ut_ck_idt(void);

#define compiler_time_assert(exp, msg){char ERR_##msg[(exp)?1:-1]; };

#endif
