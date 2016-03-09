#include "const.h"
#include "type.h"

PUBLIC char * itoa(char* str, int num){
    char *p = str;
    char ch;
    int i;
    int flag=0;

    *p++ = '0';
    *p++ = 'x';

    if(num==0){
        *p++ = '0';
    }else{
        for(i=28; i>=0; i-=4){
            ch = (num>>i) & 0xF;
            if( flag || (ch>0) ){
                flag = 1;
                ch += '0';
                if( ch > '9'){
                    ch += 7; // move to ascii "A~F"
                }
                *p++ = ch;
            }
        }
    }
    *p=0;
    return str;
}

PUBLIC char * itob(char* str, u8 num){
    char *p = str;
    char ch;
    int i;
    int flag=1;

//    *p++ = '0';
//    *p++ = 'x';

    if(num==0){
        *p++ = '0';
        *p++ = '0';
    }else{
        for(i=4; i>=0; i-=4){
            ch = (num>>i) & 0xF;
            if( flag || (ch>0) ){
                flag = 1;
                ch += '0';
                if( ch > '9'){
                    ch += 7; // move to ascii "A~F"
                }
                *p++ = ch;
            }
        }
    }
    *p=0;
    return str;
}

//for debug
PUBLIC void disp_str_t(char* str)
{
    disp_color_str(str, 0x0F);
}


PUBLIC void disp_str(char* str)
{
    disp_color_str(str, 0x0F);
}

PUBLIC void disp_u8(u8 input)
{
    char output[4];
    itob(output, input);
    disp_str(output);
}


PUBLIC void disp_int(int input)
{
    char output[16];
    itoa(output, input);
    disp_str(output);
}

PUBLIC void delay(int time)
{
    int i, j, k;
    for(k=0; k<time; k++){
        for(i=0; i<150; i++){
            for(j=0; j<10000; j++){

            }
        }
    }
}

