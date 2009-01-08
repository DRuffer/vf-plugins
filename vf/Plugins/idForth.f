\ idForth.f - Identify the Forth host

\ Copyright (c) 2009 Dennis Ruffer

\ Permission is hereby granted, free of charge, to any person obtaining a copy
\ of this software and associated documentation files (the "Software"), to deal
\ in the Software without restriction, including without limitation the rights
\ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
\ copies of the Software, and to permit persons to whom the Software is
\ furnished to do so, subject to the following conditions:

\ The above copyright notice and this permission notice shall be included in
\ all copies or substantial portions of the Software.

\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
\ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
\ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
\ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
\ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
\ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
\ THE SOFTWARE.

v.VF +include" Plugins/Plugins.f"  Plugins.version 6 checkPlugin

[defined] idForth.version 0= [IF]

4 constant idForth.version

FORTH DEFINITIONS

CR TRUE VALUE Unknown \ Try to figure out which Forth is loading this code

[defined] ENVIRONMENT? [IF]
    S" gforth" ENVIRONMENT? [IF]

        .( Using gforth version ) TYPE CR
        Unknown FALSE TO Unknown CONSTANT ForGForth
        [defined] warning 0= [IF] : warning warnings ; [THEN]

    [ELSE]
    S" ficl-version" ENVIRONMENT? [IF]

        .( Using ficl version ) TYPE CR
        Unknown FALSE TO Unknown CONSTANT ForFicl

    [ELSE]
    S" WIN32FORTH" ENVIRONMENT? [IF]

        .( Using Win32Forth ) DROP .VERSION CR
        NOSTACK WARNING @ WARNING OFF
        : WARNING NOSTACK WARNING ;
        WARNING ! TRUE CONSTANT ForWin32
        Unknown FALSE TO Unknown CONSTANT ForWin32Forth

    [ELSE]
    S" IFORTH" ENVIRONMENT? [IF]

        .( Using iForth ) DROP CR
        Unknown FALSE TO Unknown CONSTANT ForIForth

    [ELSE]
    S" FORTH-NAME" ENVIRONMENT? [IF]
        S" pfe" COMPARE 0= [IF] 

            .( Using PFE ) DROP CR
            Unknown FALSE TO Unknown CONSTANT ForPFE

        [THEN]
    [ELSE]
    S" FORTH-SYS" ENVIRONMENT? [IF]
        S" SP-FORTH" COMPARE 0= [IF]

            .( Using SP-Forth ) DROP CR
            Unknown FALSE TO Unknown CONSTANT ForSPForth

        [THEN]
    [ELSE]
        [defined] VERSION [IF]
            [defined] @R$ [IF]
                PAD 398 @R$ PAD COUNT S" Carbon MacForth " COMPARE 0= [IF]

                    .( Using ) VERSION CR
                    Unknown FALSE TO Unknown CONSTANT ForMacForth
                    : warning unique.msg ;
                    TRUE CONSTANT ForOS9
                    USE-CURRENT-FOLDER
                    SHOW.INCLUDES OFF

                [THEN]
            [ELSE]
                S" SwiftForth" VERSION OVER COMPARE 0= [IF]

                    .( Using ) VERSION ZCOUNT TYPE CR
                    TRUE CONSTANT ForWin32
                    Unknown FALSE TO Unknown CONSTANT ForSwiftForth

                [THEN]
            [THEN]
        [THEN]
    [THEN] [THEN] [THEN] [THEN] [THEN] [THEN]
[ELSE]
    [defined] timbre [IF]

        .( Using ) version CR
        Unknown FALSE TO Unknown CONSTANT ForTimbre
        variable warning

    [THEN]
[THEN] Unknown [IF]

    .( Using unknown Forth!  Be careful! ) CR
    variable warning

[THEN]

[defined] .?. 0= [IF] : .?. ( n -- )   cr .s drop ." .?. " ; [THEN]

[defined] -warning 0= [IF] variable old-warning
: -warning   warning @  old-warning !  0 warning ! ;
: +warning   old-warning @  warning ! ;
[THEN]

[THEN]
