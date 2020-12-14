; Махнач Федор, БПИ 196
; Вариант 15
format PE console

entry start

include 'win32a.inc'

section '.data' data readable writable
        sizeRequest db 'Please, enter size of the array: ', 0
        badSizeMessage db 'Size must be positive!', 0
        arrayRequest db 'Please, enter the array elements: ', 0
        resultMessage db 'Result array: ', 0


        formatNum db '%d', 0
        formatOut db '%d ', 0
        num rd 1
        minVal rd 1
        arrSize rd 1
        arrayA rd 100
        arrayB rd 100

section '.code' code readable executable
;--------------------------------------------------------------------------
start:
        ; Reading the input array
        call ReadArray

        ; Generating the array with 0's replaced by the min value
        call GenerateArray

        ; Printing B array
        call PrintArray
endprog:
        call [getch]

        push NULL
        call [ExitProcess]

;--------------------------------------------------------------------------
ReadArray:
        ; Printing size request message.
        push sizeRequest
        call [printf]
        add esp, 4

        ; Getting the size.
        push arrSize
        push formatNum
        call [scanf]
        add esp, 8

        ; Not positive size is not allowed.
        cmp [arrSize], 0
        jg actualReading
        push badSizeMessage
        call [printf]
        add esp, 4
        jmp endprog


actualReading:
        push arrayRequest
        call [printf]
        add esp, 4

        ; Getting the first element.
        push num
        push formatNum
        call [scanf]
        add esp, 8

        ; Also setting the first element to minVal.
        mov eax, [num]
        mov [arrayA], eax
        mov [minVal], eax

        ; Getting the rest.
        mov ebx, 1
loop1:
        push num
        push formatNum
        call [scanf]
        add esp, 8

        mov eax, [num]
        mov [arrayA+4*ebx], eax

        ; Checking if the value is less than min
        cmp eax, [minVal]
        jge bigger
        mov [minVal], eax

        bigger:
        inc ebx
        cmp ebx, [arrSize]
        jne loop1
ret
;--------------------------------------------------------------------------
GenerateArray:
        mov ebx, 0
loop2:
        cmp [arrayA+4*ebx], 0
        jne not_null
null:
        mov eax, [minVal]
        mov [arrayB+4*ebx], eax
        jmp loop2_end

not_null:
        mov eax, [arrayA+4*ebx]
        mov [arrayB+4*ebx], eax
        jmp loop2_end

loop2_end:
        inc ebx
        cmp ebx, [arrSize]
        jne loop2
ret
;--------------------------------------------------------------------------
PrintArray:
        push resultMessage
        call [printf]
        add esp, 4
        mov ebx, 0
loop3:
        push [arrayB+4*ebx]
        push formatOut
        call [printf]
        add esp, 8

        inc ebx
        cmp ebx, [arrSize]
        jne loop3
ret
;--------------------------------------------------------------------------
section '.idata' import data readable

        library kernel, 'kernel32.dll',\
                msvcrt, 'msvcrt.dll'

        import kernel,\
               ExitProcess, 'ExitProcess'

        import msvcrt,\
               printf, 'printf',\
               getch, '_getch',\
               scanf, 'scanf'
