/*************************************************************************//**
 *****************************************************************************
 * @file   systask.c
 * @brief  
 * @author Forrest Y. Yu
 * @date   2007
 *****************************************************************************
 *****************************************************************************/

#include "type.h"
#include "const.h"
#include "protect.h"
#include "string.h"
#include "proc.h"
#include "tty.h"
#include "console.h"
#include "global.h"
#include "keyboard.h"
#include "proto.h"


/*****************************************************************************
 *                                task_sys
 *****************************************************************************/
/**
 * <Ring 1> The main loop of TASK SYS.
 * 
 *****************************************************************************/
PUBLIC void task_sys()
{
    MESSAGE msg;
    while( 1 ){

        ERIC_DEBUG(",sys_rcv");
        // 跟系統要 msg，要不到就等待
        send_recv(RECEIVE, ANY, &msg);

        // 若task_sys 不被阻塞，那麼他的message應該就已經被填好了
        // 處理該 message
        int src = msg.source;
        switch (msg.type) {
        case GET_TICKS:
            msg.RETVAL = m_ticks;
            ERIC_DEBUG(",sys_snd_tck");
            send_recv(SEND, src, &msg);
            break;
        default:
            panic("unknown msg type");
            break;
        }
    }
}
