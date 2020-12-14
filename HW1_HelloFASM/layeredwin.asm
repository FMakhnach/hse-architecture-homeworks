;setting window transparency example by carlos hernandez/coconut

format PE GUI 4.0
entry start

ID_SCROLLBAR = 1000
ID_STATIC = 1001

include 'win32w.inc'

section '.data' data readable writeable

  _class TCHAR 'FASMWIN32',0
  _title TCHAR 'Layered window example',0
  _error TCHAR 'Startup failed.',0
  _scrollbar TCHAR 'scrollbar',0
  _static TCHAR 'static',0
  _conv TCHAR '%i',0

  hwndstatic dd ?
  hwndscroll dd ?

  buffer rb 32

  wc WNDCLASS 0,WindowProc,0,0,NULL,NULL,NULL,COLOR_BTNFACE+1,NULL,_class

  lpsi SCROLLINFO sizeof.SCROLLINFO,SIF_ALL,5,255,1,255,0

  msg MSG

section '.code' code readable executable

  start:
        invoke  GetModuleHandle,0
        mov     [wc.hInstance],eax
        invoke  LoadIcon,0,IDI_APPLICATION
        mov     [wc.hIcon],eax
        invoke  LoadCursor,0,IDC_ARROW
        mov     [wc.hCursor],eax
        invoke  RegisterClass,wc
        or      eax,eax
        jz      error
        invoke  CreateWindowEx,WS_EX_LAYERED,_class,_title,WS_VISIBLE+WS_SYSMENU,128,128,256,192,NULL,NULL,[wc.hInstance],NULL
        test    eax,eax
        jz      error
  msg_loop:
        invoke  GetMessage,msg,NULL,0,0
        or      eax,eax
        jz      end_loop
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
        jmp     msg_loop
  error:
        invoke  MessageBox,NULL,_error,NULL,MB_ICONERROR+MB_OK
  end_loop:
        invoke  ExitProcess,[msg.wParam]

proc WindowProc hwnd,wmsg,wparam,lparam
        push    ebx esi edi
        cmp     [wmsg],WM_HSCROLL
        je      wmhscroll
        cmp     [wmsg],WM_CREATE
        je      wmcreate
        cmp     [wmsg],WM_DESTROY
        je      wmdestroy
  defwndproc:
        invoke  DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
        jmp     finish
  wmhscroll:
        mov     eax,[wparam]
        cmp     ax,SB_THUMBPOSITION                      ;received when thumb stops dragging
        je      thumbposition
        cmp     ax,SB_THUMBTRACK                         ;received while thumb is dragging
        je      thumbposition
        cmp     ax,SB_LINELEFT                           ;left arrow clicked
        je      lineleft
        cmp     ax,SB_LINERIGHT                          ;right arrow clicked
        je      lineright
        cmp     ax,SB_PAGELEFT                           ;left space between arrow and thumb clicked
        je      pageleft
        cmp     ax,SB_PAGERIGHT                          ;right space between arrow and thumb clicked
        je      pageright
        jmp     defwndproc
  thumbposition:                                         ;for our purposes we'll handle both drag/stop events here
        mov     [lpsi.fMask],SIF_TRACKPOS
        invoke  GetScrollInfo,[hwndscroll],SB_CTL,lpsi
        push    [lpsi.nTrackPos]
        pop     [lpsi.nPos]
        mov     [lpsi.fMask],SIF_ALL
        jmp     update_window
  lineleft:
        cmp     [lpsi.nPos],160                           ;transparency under 5 will make window invisible/useless
        jb      defwndproc
        dec     [lpsi.nPos]
        jmp     update_window
  lineright:
        cmp     [lpsi.nPos],254                         ;transparency over 255 will make window invisible/useless
        jg      defwndproc
        inc     [lpsi.nPos]
        jmp     update_window
  pageleft:
        mov     eax,[lpsi.nPage]
        sub     [lpsi.nPos],eax
        jmp     update_window
  pageright:
        mov     eax,[lpsi.nPage]
        add     [lpsi.nPos],eax
  update_window:
        mov     ecx,[lpsi.nPos]
        push    ecx
        cinvoke wsprintf,buffer,_conv,ecx
        invoke  SendMessage,[hwndstatic],WM_SETTEXT,0,buffer
        pop     ecx
        invoke  SetLayeredWindowAttributes,[hwnd],0,ecx,LWA_ALPHA
        invoke  SetScrollInfo,[hwndscroll],SB_CTL,lpsi,1
        xor     eax,eax
        jmp     finish
  wmcreate:                                                         ;x,y,width,height
        invoke  CreateWindowEx,0,_static,_title,WS_VISIBLE+WS_CHILD,25,20,195,25,[hwnd],ID_STATIC,[wc.hInstance],NULL
        mov     [hwndstatic],eax
        invoke  CreateWindowEx,0,_scrollbar,NULL,WS_VISIBLE+WS_CHILD+SBS_HORZ,25,55,195,15,[hwnd],ID_SCROLLBAR,[wc.hInstance],NULL
        mov     [hwndscroll],eax
        invoke  SetScrollInfo,[hwndscroll],SB_CTL,lpsi,0
        invoke  SetLayeredWindowAttributes,[hwnd],0,255,LWA_ALPHA
        xor     eax,eax
        jmp     finish
  wmdestroy:
        invoke  PostQuitMessage,0
        xor     eax,eax
  finish:
        pop     edi esi ebx
        ret
endp

section '.idata' import data readable writeable

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'