#ifndef _PROTECT_H_
#define _PROTECT_H_

typedef struct s_descriptor
{
    u16 limit_low;
    u16 base_low;
    u8 base_mid;
    u8 attri;
    u8 limit_high_attri;
    u8 base_high;
}DESCRIPTOR;

#endif
