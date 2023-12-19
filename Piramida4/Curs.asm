POINT3D struc
xx  dw  
yy  dw  
zz  dw  
POINT3D ends
 

POINT2D struc
xx  dw  
yy  dw  
POINT2D ends
 

PRLINE  macro   num1, num2, colour
    mov bx, num2
    shl bx, 2
    push    colour
    push    [POINT2D ptr bx+si].yy
    push    [POINT2D ptr bx+si].xx
    mov bx, num1
    shl bx, 2
    push    [POINT2D ptr bx+si].yy
    push    [POINT2D ptr bx+si].xx
    call    Line
    add sp, 10
    endm
 
    .model  tiny, C     
    .386            
    .code           
    .startup        
    mov ax, 0013h   
    int 10h
 
    mov ax, @DATA
    mov ds, ax      
    mov ax, 0a000h
    mov es, ax      
 

    mov [DeltaX], 0 
    mov [DeltaY], 0 
    mov [DeltaZ], 0 
 

    mov [Xoff], 200 
    mov [Yoff], 200
    mov [Zoff], 600 
 
MainLoop:
    call    MainProgram 
 
    mov ah, 1       
    int 16h
    jz  MainLoop
    mov ah, 0
    int 16h
    cmp ah, 1        
    jne MainLoop
 
    mov ax, 0003h   
    int 10h
 
    mov ax, 4c00h   
    int 21h
 

UpdateAngles    PROC
    mov ax, [XAngle]
    add ax, [DeltaX]
    cmp ax, 180      
    jb  set_XAngle
    sub ax, 180
set_XAngle:
    mov [XAngle], ax
    
    mov ax, [YAngle]
    add ax, [DeltaY]
    cmp ax, 180      
    jb   set_YAngle
    sub ax, 180
set_YAngle:
    mov [YAngle], ax
 
    mov ax, [ZAngle]
    add ax, [DeltaZ]
    cmp ax, 180      
    jb  set_ZAngle
    sub ax, 180
set_ZAngle:
    mov [ZAngle], ax
    ret
UpdateAngles    ENDP
 
CalcRotation    PROC    uses si di, coord1:word, coord2:word, angle:word
    fild    angle       
    fldpi           
    fmulp           
    fdiv    c180    
    fsincos         
 
    mov di, coord1
    mov si, coord2
 
    fild    word ptr [di]   
    fild    word ptr [si]   
    
    fsubp            
    fild    word ptr [di]   
    fild    word ptr [si]   
    faddp           
 
    fistp   word ptr [si]   
    fistp   word ptr [di]   
    ret
CalcRotation    endp
 
RotatePoint PROC
    mov ax, [POINT3D ptr si].xx
    mov [X], ax
    mov ax, [POINT3D ptr si].yy
    mov [Y], ax
    mov ax, [POINT3D ptr si].zz
    mov [Z], ax
    call    CalcRotation, offset [Y], offset [Z], [XAngle]
    call    CalcRotation, offset [X], offset [Z], [YAngle]
    call    CalcRotation, offset [X], offset [Y], [ZAngle]
 
    ret
RotatePoint endp
 
Conv3Dto2D  PROC 
    mov ax, [Xoff]      
    mov bx, [X]
    imul    bx
    mov bx, [Z]
    add bx, [Zoff]      
    idiv    bx
    add ax, [Mx]        
    mov [POINT2D ptr di].xx, ax 
    mov ax, [Yoff]      
    mov bx, [Y]
    imul    bx
    mov bx, [Z]
    add bx, [Zoff]      
    idiv    bx
    add ax, [My]        
    mov [POINT2D ptr di].yy, ax 
    ret
Conv3Dto2D  ENDP
 
MainProgram PROC
    call    UpdateAngles        
 
    lea di, Cube2D      
    lea si, Cube        
    mov cx, MaxPoints   
ConvLoop:
    call    RotatePoint 
    call    Conv3Dto2D  
    add si, size POINT3D
    add di, size POINT2D
    loop    ConvLoop
 
    lea si, Cube2D      
    PRLINE  0, 1, 11
    PRLINE  1, 2, 11
    PRLINE  2, 3, 11
    PRLINE  3, 0, 11
    PRLINE  0, 4, 11
    PRLINE  1, 4, 11
    PRLINE  2, 4, 11
    PRLINE  3, 4, 11
 
    ret
MainProgram ENDP
 
Line    proc    uses di bx, x1:word, y1:word, x2:word, y2:word, color:byte
local   i:word,     \   
    delta_x:word,   \   
    delta_y:word,   \ 
    incx:word,  \   
    incy:word       
 

    mov ax, x2
    sub ax, x1      
    mov incx, 0    
    test    ax, ax      
    jz  set_delta_x 
    jg  set_x_1     
    dec incx        
    neg ax      
    jmp set_delta_x 
set_x_1:
    inc incx        
set_delta_x:
    mov delta_x, ax 
 

    mov ax, y2
    sub ax, y1      
 
    mov incy, 0     
    test    ax, ax      
    jz  set_delta_y 
    jg  set_y_1     
    dec incy        
    neg ax      
    jmp set_delta_y 
set_y_1:
    inc incy        
set_delta_y:
    mov delta_y, ax 

    cmp ax, delta_x 
    jge from_y      
    cmp delta_x, 0  
    jz  Line_ret    

    fild    delta_y
    fidiv   delta_x     
;for (int i=0;i<delta_x;i++)
    xor cx, cx      
    jmp cmp_i_x     
x_loop:             
    mov i, cx       
    fld st      
    fimul   i       
    fimul   incy        
    call    floor       
    fistp   i       
    mov ax, i       
    add ax, y1      
    mov dx, 320     
    imul    dx      
    mov bx, ax      
    mov ax, incx    
    imul    cx      
    add ax, x1      
    add ax, bx      
    mov di, ax      
 
    mov al, color   
    mov es:[di], al 
 
    inc cx      
cmp_i_x:
    cmp cx, delta_x 
    jl  x_loop
    jmp Line_ret    
 
from_y:             
    fild    delta_x
    fidiv   delta_y     ;st=k=(float)(delta_x/delta_y)
 
;for (int i=0;i<delta_y;i++)
    xor cx, cx      
    jmp cmp_i_y      
y_loop:             
    mov ax, incy    
    imul    cx      
    add ax, y1      
    mov dx, 320     
    imul    dx              
    mov bx, ax      
    mov i, cx       
    fld st      
    fimul   i       
    fimul   incx        
    call    floor       
    fistp   i       
    mov ax, i       
    add ax, x1      
 
    add ax, bx     
    mov di, ax      
 
    mov al, color   
    mov es:[di], al 
 
    inc cx      
cmp_i_y:
    cmp cx, delta_y 
    jl  y_loop
Line_ret:
    fistp   i       
    ret
Line    endp
floor   proc
local   CtrlWordOld:word, CtrlWordNew:word
    fstcw   CtrlWordOld     
    fclex               
    mov CtrlWordNew,0763h   
    fldcw   CtrlWordNew     
    frndint             
    fclex               
    fldcw   CtrlWordOld     
    ret
floor   endp 
    .data
c180    dd  180.    
Cube    POINT3D <-60, -60, -60>
    POINT3D <-60,  60, -60>
    POINT3D < 0,  60, -65>
    POINT3D < 0, -65, -60>
    POINT3D <  0,   20,  150>
 
Cube2D  POINT2D 8 dup (<>)
 
X   DW  ?   
Y   DW  ?
Z   DW  ?
 
XAngle  DW  0   
YAngle  DW  0
ZAngle  DW  0
 
DeltaX  DW  ?   
DeltaY  DW  ?
DeltaZ  DW  ?
 
Xoff    DW  ?    
Yoff    DW  ?   
Zoff    DW  ?   
 
Mx  DW  160 
My  DW  100
 
MaxPoints   EQU 8   
    END