; Programme qui additionne deux nombres
         LDA     a,d         ; inline comment
         ADDA    b,d         
         STA     c,d         
         STOP                

; useless spaces fufu regexp

a:       .WORD   3           
b:       .WORD   5           
c:       .BLOCK  2           
         .END                  
