`ifndef MY_DEFINES_SV
`define MY_DEFINES_SV

package types;
    typedef enum logic[1:0] {
        None = 0,
        WrongAnswer = 1,
        RightAnswer = 2,
        NewPassword = 3
    } event_t;

    typedef struct{
        logic [4:0] a, b; // for input
        logic [9:0] m; // for output : store multiplication result
    } port_t;
endpackage

`endif