; Programme qui additionne deux nombres
         LDA     a,d         ; inline comment
         ADDA    b,d
         STA     c,d
         STOP

; useless spaces fufu regexp

x:       .ADDRSS y
a:       .WORD   3
b:       .WORD   5
f:       .EQUATE 5
c:       .BLOCK  2
y:       .ADDRSS x
         .BYTE   200

         .ASCII "Debogu\x01\\age"
         .END
