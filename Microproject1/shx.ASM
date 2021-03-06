; ������ �����, ��� 196
; ������� 15
format PE console

entry start

include 'win32a.inc'

; ���������� fp �������� �� ������ ������ � ������ ����� ������� edx
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

        x            dq  1 ; �������� ������������� ��������
        res          dq  1 ; ���������

        xSqr         dq  1 ; ������� �������� x (����� �� ��������� ������ ���)
        term         dq  1 ; ���������� ��������� ����� ���������� ����
        lastDenomN   dd  1 ; ��������� �����, �� ������� �� ������ (n � n!, ������� � �����������)

        accuracy     dq  1e-12 ; "� ��������� �� ���� 0,1%" <=> ����� � ������. � �� � 0.1% ���-�� ������ ������� �� ������� ������
        upperBound   dq  1e10  ; ��������, ����� �������� �� �������� �������� � ���������������� �������. ����� ��� ������� ����������� ����� (�� ������)

section '.code' code readable executable
;--------------------------------------------------------------------------
start:
        FINIT

        invoke  printf, inputRequest
        invoke  scanf, fmtFlt, x, holder
        cmp     eax, 0
        jne     calculation

        invoke  scanf, fmts, holder ; ��������� ������ �� �����, ������������ �� ������ (����� ����� �������� �� ��������� ��������)
        invoke  printf, wrongInput  ; �������� � �������� �����
        jmp     endprog

calculation:
        invoke  printf, newLine
        Movf    res, x  ; ���������� � ��������� ����� �

        fld     [x]
        fldz
        fcomp           ; �������� �� ����
        fstsw   ax
        sahf
        je      output

        fabs
        fld     [upperBound]
        fcompp          ; �������� �� ������� ������� ��������
        fstsw   ax
        sahf
        jb      infty_case

correct_input_val:
        Movf    term, x ; ������ ��������� -- ���� ����� �
        Movf    xSqr, x ; ���������� � xSqr �������� x^2 ����� �� ������� ��� ������ ���
        fld     [xSqr]
        fmul    [x]
        fstp    [xSqr]

        mov     [lastDenomN], 1
        mov     ebx, 1  ; �������
calculation_loop:
        ; ��������� ��������� ���������, ������� ���������� �� x^2 / (n*(n + 1))
        fld     [term]
        fmul    [xSqr]
        inc     [lastDenomN]
        fidiv   dword[lastDenomN]
        inc     [lastDenomN]
        fidiv   dword[lastDenomN]
        fstp    [term]

        ; ��������� ��������� � ����������
        fld     [res]
        fadd    [term]
        fstp    [res]

        ; ������� ���������, ���������� �������� �������������� ����������
        call    PrintMidResult
        inc     ebx

        ; ���������, �������� �� �������� ��������������
        fstsw   ax
        and     ax, 1000b
        cmp     ax, 0
        jg      infty_case

        ; ���������� ��������� ����������: |res_i - res_{i - 1}| / |res_i|
        ; �������� ��� ������� ��� ������ term, term ����� ��� �� ����, ��� � res ������� ������ ���������� term/res � accuracy
        fld     [res]
        fld     [term]
        fdivrp  st1, st0
        fld     [accuracy]
        fcompp
        fstsw   ax
        sahf
        jb      calculation_loop  ; ���� accuracy ������, ��� term/res -- ���������� ��������� �����

output:
        ; ������� ���������
        invoke  printf, newLine
        call    PrintResult

endprog:
        invoke  printf, newLine
        jmp     start      ; ����������� ����, ��

infty_case:
        fld     [x]
        fldz
        fcompp
        fstsw   ax
        sahf
        jbe     sv_inf     ; ���� �������� ������ ����, �� ��� ���. ����.
        invoke  printf, outMsgStr, dword[x], dword[x+4], negInfty
        jmp     endprog

sv_inf:
        invoke  printf, outMsgStr, dword[x], dword[x+4], infty
        jmp     endprog

;--------------------------------------------------------------------------
PrintMidResult: ; ��� ������� �������� (>upperBound) �� ������� �������� � ���������������� �����
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
PrintResult: ; ��� ������� �������� (>upperBound) �� ������� �������� � ���������������� �����
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