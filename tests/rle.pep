;
; Auteur : Frédéric Vachon
;
; Description du programme :
;
;  Ce programme permet d'encoder une série de caractères
;  saisis. Il s'agit d'un codage par plage qui consiste à faire
;  précéder un caractère qui se répète plusieurs fois successives
;  par le nombre d'occurences de celui-ci.
;
;  Entrée : plusieurs caractères
;  Sortie : la chaîne de caractère encodée
;
;  LIMITE : Ce programme ne prend en entrée que les caractères qui font
;           partie du code ASCII étendu. À titre d'exemple, les caractères
;           arabes, hébreux et mandarins ne sont pas supportés.

         CHARI   buffer,d    ; char buffer = saisie clavier
         LDA     0,i         ;
         LDBYTEA buffer,d    ;
condwh:  CPA     '\n',i      ; while ( buffer != '\n' ) {
         BREQ    finprog     ;
boucle:  nop0                ;    while ( in == buffer ) { 
         CHARI   in,d        ;        char in = saisie clavier
         LDA     0,i         ;
         LDBYTEA in,d        ;
         CPA     buf16bit,d  ;    
         BRNE    testrec     ;
         LDA     1,i         ;
         ADDA    recur,d     ;
         STA     recur,d     ;        recur++
         BR      boucle      ;    }
testrec: LDA     recur,d     ;
         CPA     9,i         ;
         BRLE    condUn      ;    while ( recur > 9 ) {
         DECO    9,i         ;        
         CHARO   buffer,d    ;        print("9" + buffer)
         LDA     recur,d     ;
         SUBA    9,i         ;        recur -= 9
         STA     recur,d     ;
         BR      testrec     ;    }
condUn:  LDA     recur,d     ;    
         CPA     2,i         ;
         BRLE    verifch     ;    if ( reccurence > 2 ) {
print:   DECO    recur,d     ;        
         CHARO   buffer,d    ;        print(recur + buffer)
         BR      finwhile    ;
;Le code suivant détermine s'il s'agit d'un chiffre entre 1 et 9 inclusivement
verifch: LDA     0,i         ;
         LDBYTEA buffer,d    ;
         CPA     0x0031,i    ;
         BRLT    caract      ;    } else if ( buffer est un chiffre ) {
         LDA     0,i         ;    
         LDBYTEA buffer,d    ;         print(recur + buffer)
         CPA     0x0039,i    ;
         BRGT    caract      ;
         BR      print       ;
                             ;    } else {
caract:  NOP0                ;        while ( recur != 0 ) {
         CHARO   buffer,d    ;            print(buffer)
         LDX     recur,d     ;    
         SUBX    1,i         ;        
         STX     recur,d     ;
         CPX     0,i         ;    
         BREQ    finwhile    ;    
         BR      caract      ;        }
                             ;    }
finwhile:LDA     0,i         ;
         LDBYTEA in,d        ;
         STBYTEA buffer,d    ;    buffer = in
         LDA     1,i         ;
         STA     recur,d     ;    recur = 1
         BR      condwh      ; }
finprog: CHARO   '\n',i      ; print ('\n')
         STOP                ; FIN DU PROGRAMME
                             ;
buf16bit:.BYTE   0           ; C'est le buffer mais codé sur 16 bits servant pour les comparaisons
buffer:  .BYTE   ' '         ; Caractère qui est une mémoire tampon contenant l'avant dernier caractère saisi          
in:      .BYTE   ' '         ; Caractère qui contient l'entrée la plus récente de l'utilisateur
recur:   .WORD   1           ; Entier qui contient le nombre de récurrences successives d'un caractère
         .END                  
