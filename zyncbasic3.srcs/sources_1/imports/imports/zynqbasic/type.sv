`ifndef TYPES
`define TYPES

package types;
    typedef enum logic[1:0] {
        None = 0,
        WrongAnswer = 1,
        RightAnswer = 2,
        NewPassword = 3
    } event_t;
endpackage

`endif