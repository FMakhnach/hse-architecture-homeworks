; Махнач Федор, БПИ 196
; Вариант 15
format PE console

entry start

include 'win32a.inc'

; Перемещает fp значение из одного адреса в другой через регистр edx
macro Movf dstf, srcf {
  mov edx, dword[srcf]
  mov dword[dstf], edx
  mov edx, dword[srcf+4]
  mov dword[dstf+4], edx
}


section '.data' data readable writable
        inputRequest db  'Please, enter value x: ', 0
        wrongInput   db  'Wrong input!', 13, 10, 0
        calcMsg      db  'Cycle #%d:', 9, '%.15lf', 13, 10, 0
        calcMsgExp   db  'Cycle #%d:', 9, '%.15e', 13, 10, 0
        outMsg       db  'Value of hyperbolic sine at point %.4lf is %.15lf', 13, 10, 0
        outMsgExp    db  'Value of hyperbolic sine at point %.4lf is %.15e', 13, 10, 0
        outMsgStr    db  13, 10, 'Value of hyperbolic sine at point %.4lf is %s', 13, 10, 0

        fmtFlt       db  '%lf', 0
        fmts         db  '%s', 0
        newLine      db  13, 10, 0
        infty        db  'INFTY', 0
        negInfty     db  'NEG_INFTY', 0
        holder       db  0

        x            dq  1 ; Вводимое пользователем значение
        res          dq  1 ; Результат

        xSqr         dq  1 ; Квадрат значения x (чтобы не вычислять каждый раз)
        term         dq  1 ; Предыдущее слагаемое суммы степенного ряда
        lastDenomN   dd  1 ; Последнее число, на которое мы делили (n в n!, который в знаменателе)

        accuracy     dq  1e-12 ; "с точностью не хуже 0,1%" <=> можно и точнее. А то с 0.1% как-то совсем грустно на больших числах
        upperBound   dq  1e10  ; Значение, после которого мы начинаем выводить в экспоненциальном формате. Также это граница допустимого ввода (по модулю)

section '.code' code readable executable
;--------------------------------------------------------------------------
start:
        FINIT

        invoke  printf, inputRequest
        invoke  scanf, fmtFlt, x, holder
        cmp     eax, 0
        jne     calculation

        invoke  scanf, fmts, holder ; Считываем строку до конца, освобождаясь от буфера (чтобы сканф сработал на следующей итерации)
        invoke  printf, wrongInput  ; Сообщаем о неверном вводе
        jmp     endprog

calculation:
        invoke  printf, newLine
        Movf    res, x  ; Записываем в результат число х

        fld     [x]
        fldz
        fcomp           ; Проверка на ноль
        fstsw   ax
        sahf
        je      output

        fabs
        fld     [upperBound]
        fcompp          ; Проверка на слишком большое значение
        fstsw   ax
        sahf
        jb      infty_case

correct_input_val:
        Movf    term, x ; Первое слагаемое -- само число х
        Movf    xSqr, x ; Записываем в xSqr значение x^2 чтобы не считать его каждый раз
        fld     [xSqr]
        fmul    [x]
        fstp    [xSqr]

        mov     [lastDenomN], 1
        mov     ebx, 1  ; Счётчик
calculation_loop:
        ; Вычисляем очередное слагаемое, умножая предыдущее на x^2 / (n*(n + 1))
        fld     [term]
        fmul    [xSqr]
        inc     [lastDenomN]
        fidiv   dword[lastDenomN]
        inc     [lastDenomN]
        fidiv   dword[lastDenomN]
        fstp    [term]

        ; Добавляем слагаемое к результату
        fld     [res]
        fadd    [term]
        fstp    [res]

        ; Выводим сообщение, содержащее значение промежуточного результата
        call    PrintMidResult
        inc     ebx

        ; Проверяем, является ли значение бесконечностью
        fstsw   ax
        and     ax, 1000b
        cmp     ax, 0
        jg      infty_case

        ; Необходимо вычислить отклонение: |res_i - res_{i - 1}| / |res_i|
        ; Значение под модулем это просто term, term имеет тот же знак, что и res поэтому просто сравниваем term/res с accuracy
        fld     [res]
        fld     [term]
        fdivrp  st1, st0
        fld     [accuracy]
        fcompp
        fstsw   ax
        sahf
        jb      calculation_loop  ; Если accuracy больше, чем term/res -- продолжаем вычислять сумму

output:
        ; Выводим результат
        invoke  printf, newLine
        call    PrintResult

endprog:
        invoke  printf, newLine
        jmp     start      ; Бесконечный цикл, да

infty_case:
        fld     [x]
        fldz
        fcompp
        fstsw   ax
        sahf
        jbe     sv_inf     ; Если значение больше нуля, то это пол. беск.
        invoke  printf, outMsgStr, dword[x], dword[x+4], negInfty
        jmp     endprog

sv_inf:
        invoke  printf, outMsgStr, dword[x], dword[x+4], infty
        jmp     endprog

;--------------------------------------------------------------------------
PrintMidResult: ; При большом значении (>upperBound) мы выводим значение в экспоненциальной форме
        fld     [res]
        fabs
        fld     [upperBound]
        fcompp
        fstsw   ax
        sahf
        jb      PrintMidResult_exp_output

        invoke  printf, calcMsg, ebx, dword[res], dword[res+4]
        add     esp, 16
ret

PrintMidResult_exp_output:
        invoke  printf, calcMsgExp, ebx, dword[res], dword[res+4]
        add     esp, 16
ret
;--------------------------------------------------------------------------
PrintResult: ; При большом значении (>upperBound) мы выводим значение в экспоненциальной форме
        fld     [res]
        fabs
        fld     [upperBound]
        fcompp
        fstsw   ax
        sahf
        jb      PrintResult_exp_output

        invoke  printf, outMsg, dword[x], dword[x+4], dword[res], dword[res+4]
        add     esp, 20
ret

PrintResult_exp_output:
        invoke  printf, outMsgExp, dword[x], dword[x+4], dword[res], dword[res+4]
        add     esp, 20
ret
;--------------------------------------------------------------------------
section '.idata' import data readable

        library kernel, 'kernel32.dll',\
                msvcrt, 'msvcrt.dll'

        import  kernel,\
                ExitProcess, 'ExitProcess'

        import  msvcrt,\
                printf, 'printf',\
                getch, '_getch',\
                scanf, 'scanf'