;
;  ### I N F 2 1 7 0 ###
;  ###    Gr : 50    ###
;  
;  ###   TP3: Trie   ### 
; 
;  @author : Frédéric Vachon
; 
;  @version : 2013-11-30
;
;  Description du programme :
;
;	  Ce programme implémente une structure de donnée de type arbre préfixe (radix tree)
;    qui permet à l'utilisateur de stocker des mots en mémoire. L'utilisateur peut;
; 	  ensuite afficher tous les mots de l'arbre avec leur occurrence, chercher ou supprimer
; 	  un mot en particulier et obtenir le nombre de mots dans l'arbre.
; 
;  Commandes :
;
;	  1 : Affiche le nombre de mots différents saisis, une barre oblique, le nombre de mots 
; 	   total saisi et un saut de ligne. 
; 
;	  2 : Affiche tous les mots différents du trie par ordre alphabétique suivi du nombre 
; 		d'occurrences de chacun.
; 
;	  3 : Suivi d'un mot, cette commande affiche le mot suivi de son nombre d'occurrences.
; 
;	  4 : Suivi d'un mot, cette commande supprime toutes les occurrences de ce mot.
; 
;	  5 : Affiche tous les mots de l'arbre en ordre décroissant d'occurrences suivi du
; 		nombre d'occurrences de chacun.
; 
;	  0 : Quitte le programme. 
; 
;  LIMITE : Ce programme ne fonctionne qu'avec des mots composés uniquement de 
;           lettres minuscules sans caractères spéciaux.
;
         LDA     0,i         
         LDX     0,i         
loop:    NOP0                ; while ( in != 0 ) {
         CHARI   in,d        ;   in = Pep8.chari();
         LDA     0,i         
         LDBYTEA in,d        
         CPA     '1',i       ;   if ( in == '1' ) {
         BRNE    case2       
         SUBSP   2,i         ; #argNbMot
         LDX     noeud,i     
         LDA     0,i         
         STA     argNbMot,s  
         CALL    nbMots      
         STA     buffer,d    
         DECO    buffer,d    ;     Pep8.deco(nombreDeMot(trie, false));
         CHARO   '/',i       ;     Pep8.charo('/');
         LDA     1,i         
         STA     argNbMot,s  
         CALL    nbMots      
         ADDSP   2,i         ; #argNbMot
         STA     buffer,d    
         DECO    buffer,d    ;     Pep8.deco(nombreDeMot(trie, true));
         CHARO   '\n',i      ;     Pep8.charo('\n');
         NOP0                
         BR      loop        
case2:   CPA     '2',i       ;   } else if ( in == '2' ) {
         BRNE    case3       
         LDX     noeud,i     
         CALL    affAlpha    ;     affAlpha( trie );
         BR      loop        
case3:   CPA     '3',i       ;   } else if ( in == '3' ) {
         BRNE    case4       
         LDX     noeud,i     
         CHARI   in,d        
         LDA     0,i         
         LDBYTEA in,d        
         CALL    delSpace    
         CALL    find        ;     find( trie, delSpaces(Pep8.chari()) );
         BR      loop        
case4:   CPA     '4',i       ;   } else if ( in == '4' ) {
         BRNE    case5       
         LDX     noeud,i     
         CHARI   in,d        
         LDA     0,i         
         LDBYTEA in,d        
         CALL    delSpace    
         CALL    remove      ;     remove( trie, delSpaces(Pep8.chari()) );
         BR      loop        
case5:   CPA     '5',i       ;   } else if ( in == '5' ) {
         BRNE    caseLett   
         LDX noeud, i         
         CALL    affParOc    ;     affParOc(trie);
         BR      loop        
caseLett:LDA     0,i         ;   } else if ( isLetter(in) ) {
         LDBYTEA in,d        
         SUBSP   2,i         ; #retIsLet
         CALL    isLetter    
         LDA     retIsLet,s  
         ADDSP   2,i         ; #retIsLet
         CPA     1,i         
         BRNE    case0       
         LDX     0,i         
         LDBYTEX in,d        
         LDA     noeud,i     
         CALL    add         ;     add( trie, in );
         BR      loop        ;   } else if ( in == '0' ) {
case0:   LDA     0,i         
         LDBYTEA in,d        
         CPA     '0',i       
         BRNE    loop        
         STOP                ;     Pep8.stop();
         NOP0                ; }
retIsLet:.EQUATE 0           ; #2d valeur de retour du sous-programme isLetter
argNbMot:.EQUATE 0           ; #2d paramètre du sous-programme nbMots
in:      .BLOCK  1           ; Saisie clavier #1c
buffer:  .BLOCK  2           ; Mémoire tampon pour manipuler des valeurs
;
; Structure de donnée : Noeud
;
noeud:   .BLOCK  57          ;
nChild:  .EQUATE 0           ; Tableau contenant l'adresse mémoire des enfants #2h26a
nParent: .EQUATE 52          ; Adresse mémoire du parent #2h
nNumber: .EQUATE 54          ; Nombre d'occurences #2d
nValue:  .EQUATE 56          ; Valeur du Noeud (caractère) #1c
nTaille: .EQUATE 57          ; Taille en octets d'un Noeud
nTailCh: .EQUATE 52          ; Taille du tableau Child (nombre d'éléments)
;
; Sous-programme qui ajoute un mot saisi en entré à l'arbre.
;
; IN : A : adresse du Noeud racine de l'arbre
;      X : caractère : la première lettre minuscule saisie en entrée
; OUT: pas de sortie
;
add:     SUBSP   9,i         ; #addChild #addSavA #addChar #addNoeud #addIndex
         STA     addNoeud,s  
         STA     addSavA,s   
         STBYTEX addChar,s   
         LDA     0,i         
         LDBYTEA addChar,s   
         CALL    toIndex     
         STX     addIndex,s  ; int i = toIndex(c);
         SUBSP   2,i         ; #addLettr
         CALL    isLetter    
         LDA     addLettr,s  
         ADDSP   2,i         ; #addLettr
         CPA     0,i         
         BREQ    addNotLt    ; if ( isLetter(c) ) {
         LDX     addIndex,s  
         LDA     addNoeud,sxf
         CPA     0,i         
         BRNE    addAvecC    ;   if ( noeud.child[i] == null ) {
         LDA     nTaille,i   
         CALL    new         
         STX     addChild,s  
         LDA     addChild,s  
         LDX     addIndex,s  
         STA     addNoeud,sxf;     noeud.child[i] = new Node();
         LDX     addChild,s  
         LDA     0,i         
         LDBYTEA addChar,s   
         CALL    setValue    ;     noeud.child[i].value = c;
         LDA     addNoeud,s  
         LDX     addChild,s  
         CALL    setParen    ;     noeud.child[i].parent = noeud;
         LDA     addChild,s  
         CHARI   addChar,s   
         LDX     0,i         
         LDBYTEX addChar,s   
         CALL    add         ;     add( noeud.child[i], Pep8.chari() );
         BR      addFin      
addAvecC:NOP0                ;   } else {
         CHARI   addChar,s   
         LDX     0,i         
         LDBYTEX addChar,s   
         CALL    add         ;     add( noeud.child[i], Pep8.chari() );
         BR      addFin      ;   }
addNotLt:LDX     addNoeud,s  ; } else {
         CALL    incNum      ;   noeud.number++;
addFin:  LDA     addSavA,s   ; }
         LDX     0,i         
         LDBYTEX addChar,s   
         ADDSP   9,i         ; #addChild #addSavA #addChar #addNoeud #addIndex
         RET0                
addIndex:.EQUATE 0           ; #2d Index du child
addNoeud:.EQUATE 2           ; #2h adresse du noeud
addChar: .EQUATE 4           ; #1c Caractère saisi
addSavA: .EQUATE 5           ; #2h Tampon pour garder A
addChild:.EQUATE 7           ; #2h adresse du child
addLettr:.EQUATE 0           ; #2h Réponse au call isLetter
;
; Sous-programme qui retourne le nombre de mots (différents ou totaux) dans l'arbre
; passé en paramètre.
;
;  IN : X : addresse de la racine de l'arbre
;       SP +0  decimal -> 1 : retourne le nombre total de mots dans l'arbre
;                         0 : retourne le nombre de mots différents dans l'arbre
;  OUT: A : Le nombre de mots dans l'arbre
;
nbMots:  SUBSP   6,i         ; #nMSavX #nMIndex #nMCompt
         LDA     0,i         
         STX     nMSavX,s    
         STA     nMCompt,s   ; int compteur = 0;
nbLoop:  CPA     nTailCh,i   ; for ( int i = 0; i < noeud.child.length; i++ ) {
         BRGE    nbCond      
         STA     nMIndex,s   
         LDX     nMSavX,s    
         LDX     nMIndex,sxf 
         CPX     0,i         
         BREQ    nbInc       ;   if ( noeud.child[i] != null ) {
         LDA     nMTotal,s   
         SUBSP   2,i         ; #nMTotArg
         STA     nMTotArg,s  
         CALL    nbMots      
         ADDSP   2,i         ; #nMTotArg
         ADDA    nMCompt,s   
         STA     nMCompt,s   ;     compteur += nombreDeMot(noeud.child[i], nMTotal);
nbInc:   LDA     nMIndex,s   ;   }
         ADDA    2,i         
         BR      nbLoop      ; }
nbCond:  LDX     nMSavX,s    
         LDA     nNumber,x   
         CPA     0,i         
         BRLE    nbFin       ; if ( noeud.number > 0 ) {
         LDA     nMTotal,s   
         CPA     0,i         
         BREQ    nbNotTot    ;   if (total) {
         LDA     nMCompt,s   
         ADDA    nNumber,x   
         STA     nMCompt,s   ;     compteur += noeud.number;
         BR      nbFin       ;   } else {
nbNotTot:LDA     nMCompt,s   
         ADDA    1,i         
         STA     nMCompt,s   ;     compteur++;
nbFin:   LDA     nMCompt,s   ; }
         LDX     nMSavX,s    
         RET6                ; return compteur;  #nMSavX #nMIndex #nMCompt
nMCompt: .EQUATE 0           ; #2d Compteur de mots
nMIndex: .EQUATE 2           ; #2d Index du child
nMSavX:  .EQUATE 4           ; #2h sauvegarde la valeur du X
nMTotal: .EQUATE 8           ; #2d Paramètre booléen vrai pour avoir le total
nMTotArg:.EQUATE 0           ; #2d Paramètre booléen pour l'appel récursif
;
; Sous-programme qui prend en paramètre le noeud contenant le dernier caractère d'un
; mot et l'affiche à l'écran.
;
;  IN : X : addresse du noeud contenant la dernière lettre du mot à afficher
;  OUT: Pas de sortie
;
print:   SUBSP   4,i         ; #prNoeud #prSavA
         STA     prSavA,s    
         STX     prNoeud,s   
         LDX     nParent,x   
         CPX     0,i         
         BREQ    printFin    ; if ( noeud.parent != null ) {
         CALL    print       ;   print( noeud.parent );
         LDX     nValue,i    
         CHARO   prNoeud,sxf ;   Pep8.charo( noeud.value );
printFin:LDX     prNoeud,s   ; }
         LDA     prSavA,s    
         RET4                ; #prNoeud #prSavA
prSavA:  .EQUATE 0           ; #2h tampon pour le A
prNoeud: .EQUATE 2           ; #2h adresse du noeud
;
; Sous-programme affichant, en ordre alphabétique, tous les mots de l'arbre dont le
; nombre d'occurences est passé en paramètre.
;
;  IN : X: adresse de la racine de l'arbre
;       A: le nombre d'occurences des mots à afficher.
;  OUT: pas de sortie
;
;  LIMITE : Le nombre d'occurence doit être strictement supérieur à 0
;
printOcc:SUBSP   6,i         ; #prOOccur #prOIndex #prONoeud
         STX     prONoeud,s  
         STA     prOOccur,s  
         LDA     nNumber,x   
         CPA     prOOccur,s  
         BRNE    prOcNext    ; if ( noeud.number == occur ) {
         CALL    print       ; print ( noeud );
         CALL    affOccur    ; affOccur ( noeud );
prOcNext:LDA     0,i         
prOcLoop:CPA     nTailCh,i   ; for ( int i = 0; i < noeud.child.length; i++ ) {
         BRGE    prOcFin     
         STA     prOIndex,s  
         LDX     prONoeud,s  
         LDX     prOIndex,sxf
         CPX     0,i         
         BREQ    prOcInc     ;   if ( noeud.child[i] != null ) {
         LDA     prOOccur,s  
         CALL    printOcc    ;     printOcc( noeud.child[i], occur );
prOcInc: LDA     prOIndex,s  ;   }
         ADDA    2,i         
         BR      prOcLoop    ; }
prOcFin: LDA     prOOccur,s  
         LDX     prONoeud,s  
         RET6                ; #prOOccur #prOIndex #prONoeud
prONoeud:.EQUATE 0           ; #2h adresse du noeud
prOIndex:.EQUATE 2           ; #2d index du child dans le tableau
prOOccur:.EQUATE 4           ; #2d nombre d'occurence des mots à afficher
;
; Sous-programme qui affiche alphabétiquement tous les mots qui se trouvent
; dans l'arbre passé en paramètre suivis de leur nombre d'occurences.
;
;  IN : X : Adresse de la racine de l'arbre
;  OUT: pas de sortie
;
affAlpha:SUBSP   6,i         ; #affCompt #affNoeud #affSavA
         STA     affSavA,s   
         STX     affNoeud,s  
         LDX     nNumber,x   
         CPX     0,i         
         BRLE    affPrLo     ; if ( noeud.number > 0 ) {
         LDX     affNoeud,s  
         CALL    print       ;   print( noeud );
         CALL    affOccur    ;   printOccur( noeud );
         NOP0                
affPrLo: LDX     0,i         ; }
affLoop: CPX     nTailCh,i   
         BRGE    affFin      ; for ( int i = 0; i < 26; i++ ) {
         STX     affCompt,s  
         LDX     affNoeud,sxf
         CPX     0,i         
         BREQ    affInc      ;   if ( noeud.child[i] != null )
         CALL    affAlpha    ;     afficheAlpha( noeud.child[i] );
affInc:  LDX     affCompt,s  
         ADDX    2,i         
         BR      affLoop     
affFin:  LDA     affSavA,s   ; }
         LDX     affNoeud,s  
         RET6                ; #affCompt #affNoeud #affSavA
affSavA: .EQUATE 0           ; #2h  mémoire tampon pour stocker le A
affNoeud:.EQUATE 2           ; #2h  Adresse du noeud
affCompt:.EQUATE 4           ; #2d  Compteur pour la boucle for
;
; Sous-programme qui affiche tous les mots de l'arbre en ordre décroissant d'occurrences,
; suivi du nombre d'occurrences de chaque mot.
;
;  IN : X: adresse de la racine de l'arbre
;  OUT: pas de sortie
;
affParOc:SUBSP   4,i         ; #affOcMax #affOcSav
         STA     affOcSav,s  
         CALL    getMax      
         STA     affOcMax,s  
affOcLoo:CPA     0,i         ; for ( int i = getMax(noeud); i > 0; i-- ) {
         BRLE    affOcFin    
         CALL    printOcc    ;   printOcc( noeud, i );
         SUBA    1,i         
         BR      affOcLoo    ; }
affOcFin:LDA     affOcSav,s  
         RET4                ; #affOcMax #affOcSav
affOcSav:.EQUATE 0           ; #2h garde la valeur de A
affOcMax:.EQUATE 2           ; #2d occurrence maximale de l'arbre
; Sous-programme qui supprime un mot de l'arbre.
;
;  IN: X : adresse de la racine de l'arbre
;      A : le premier caractère saisie du mot à effacer
;  OUT: pas de sortie
;
;  LIMITE : Le mot doit être présent dans l'arbre
;
remove:  SUBSP   5,i         ; #remSavX #remSavA #remIn
         STA     remSavA,s   
         STX     remSavX,s   
         SUBSP   2,i         ;#retIsLet
         CALL    isLetter    
         LDA     retIsLet,s  
         ADDSP   2,i         ; #retIsLet
         CPA     1,i         
         BREQ    remElse     ; if ( !isLetter(c) ) {
         LDA     0,i         
         STA     nNumber,x   ;   noeud.number = 0;
         BR      remFin      
remElse: LDA     remSavA,s   
         CALL    toIndex     
         LDX     remSavX,sxf 
         CPX     0,i         
         BREQ    remFin      ; } else if ( noeud.child[toIndex(c)] != null ) {
         CHARI   remIn,d     
         LDA     0,i         
         LDBYTEA remIn,d     
         CALL    remove      ;   remove(noeud.child[toIndex(c)], Pep8.chari());
remFin:  LDA     remSavA,s   ; }
         LDX     remSavX,s   
         RET5                ; #remSavX #remSavA #remIn
remIn:   .EQUATE 0           ; #1c Le caractère saisi
remSavA: .EQUATE 1           ; #2h Sauvegarde la valeur de A
remSavX: .EQUATE 3           ; #2h Sauvegarde la valeur de X
;
; Sous-programme qui trouve un mot saisie au clavier et l'affiche suivi de son
; nombre d'occurence dans l'arbre.
;
;  IN: X : adresse de la racine de l'arbre
;      A : le premier caractère saisie du mot à effacer
;  OUT: pas de sortie
;
find:    SUBSP   5,i         ; #findSavX #findSavA #findIn
         STA     findSavA,s  
         STX     findSavX,s  
         SUBSP   2,i         ;#retIsLet
         CALL    isLetter    
         LDA     retIsLet,s  
         ADDSP   2,i         ; #retIsLet
         CPA     1,i         
         BREQ    findElse    ; if ( !isLetter(c) ) {
         CALL    print       ;   print(noeud);
         CALL    affOccur    ;   affOccur(noeud);
         BR      findFin     
findElse:LDA     findSavA,s  
         CALL    toIndex     
         LDX     findSavX,sxf
         CPX     0,i         
         BREQ    findEls2    ; } else if ( noeud.child[toIndex(c)] != null ) {
         CHARI   findIn,d    
         LDA     0,i         
         LDBYTEA findIn,d    
         CALL    find        ;   find(noeud.child[toIndex(c)], Pep8.chari());
         BR      findFin     
findEls2:LDX     findSavX,s  ; } else {
         CALL    print       ;   print(noeud);
         LDA     findSavA,s  
         STBYTEA findIn,s    
findLoop:SUBSP   2,i         ;    while ( isLetter(c) ) { #retIsLet
         CALL    isLetter    
         LDA     retIsLet,s  
         ADDSP   2,i         ; #retIsLet
         CPA     1,i         
         BRNE    findPrnt    
         CHARO   findIn,s    ;     Pep8.charo(c);
         CHARI   findIn,s    ;     c = Pep8.chari();
         LDA     0,i         
         LDBYTEA findIn,s    
         BR      findLoop    ;   }
findPrnt:CHARO   ' ',i       ;   Pep8.charo(' ');
         DECO    0,i         ;   Pep8.deco(0);
         CHARO   '\n',i      ;   Pep8.charo('\n');
findFin: LDA     findSavA,s  ; }
         LDX     findSavX,s  
         RET5                ; #findSavX #findSavA #findIn
findIn:  .EQUATE 0           ; #1c Le caractère saisi
findSavA:.EQUATE 1           ; #2h Sauvegarde la valeur de A
findSavX:.EQUATE 3           ; #2h Sauvegarde la valeur de X
; Sous-programme qui attribut un parent au Noeud
;
; IN : A: adresse mémoire du parent
;      X: adresse mémoire du Noeud
;
setParen:SUBSP   4,i         ; #sPsavX #sPaddr
         STX     sPsavX,s    
         ADDX    nParent,i   
         STX     sPaddr,s    
         STA     sPaddr,sf   ; Noeud.parent = A
         LDX     sPsavX,s    
         RET4                ; #sPsavX #sPaddr
sPaddr:  .EQUATE 0           ; #2h adresse de la valeur Parent du noeud
sPsavX:  .EQUATE 2           ; #2h tampon pour le X
;
; Sous-programme qui ajoute 1 au Number du noeud
;
; IN : X: adresse mémoire du Noeud
;
incNum:  SUBSP   6,i         ; #incSavA #incSavX #incAddr
         STA     incSavA,s   
         STX     incSavX,s   
         ADDX    nNumber,i   
         STX     incAddr,s   
         LDA     incAddr,sf  
         ADDA    1,i         
         STA     incAddr,sf  ; Noeud.number = A
         LDA     incSavA,s   
         LDX     incSavX,s   
         RET6                ; #incSavA #incSavX #incAddr
incAddr: .EQUATE 0           ; #2h adresse mémoire de la valeur Number du noeud
incSavX: .EQUATE 2           ; #2h tampon pour le X
incSavA: .EQUATE 4           ; #2h tampon pour le A
;
; Sous-programme qui attribut une valeur à Value du Noeud
;
; IN : A: valeur à attribuer
;      X: adresse mémoire du Noeud
;
setValue:SUBSP   4,i         ; #sVsavX #sVaddr
         STX     sVsavX,s    
         ADDX    nValue,i    
         STX     sVaddr,s    
         STBYTEA sVaddr,sf   ; Noeud.number = A
         LDX     sVsavX,s    
         RET4                ; #sVsavX #sVaddr
sVaddr:  .EQUATE 0           ; #2h adresse de la valeur Value du noeud
sVsavX:  .EQUATE 2           ; #2h tampon pour X
;
; Sous-programme qui lit tous les espaces et renvoie le premier caractère
; qui n'est pas un espace.
;
; IN : A : Le caractère saisi
; OUT : A : char Le premier caractère qui n'est pas un espace
;
delSpac: SUBSP   1,i         ; #delTemp
delLoop: CPA     ' ',i       ; while ( c == ' ' ) {
         BRNE    finDel      
         CHARI   delTemp,s   ;    c = Pep8.chari();
         LDA     delTemp,s   
         BR      delLoop     ; }
finDel:  RET1                ; return c;   #delTemp
delTemp: .EQUATE 0           ; #1c tampon pour caractère
;
; Sous-programme utilitaire servant à convertir un caractère en index de tableau.
;
; IN: A la lettre à convertir
; OUT: X  l'index
; LIMITE : Prend seulement une lettre minuscule en paramètre
;
toIndex: SUBSP   1,i         ; #tITemp
         STBYTEA tITemp,s    
         LDX     0,i         
         LDBYTEX tITemp,s    
         SUBX    0x0061,i    ; return c - 0x61;
         ASLX                
         RET1                ; #tITemp
tITemp:  .EQUATE 0           ; #1c tampon pour caractère
;
; Sous-programme utilitaire déterminant si le caractère en paramètre est une lettre
; minuscule.
;
; IN : A le caractère à vérifier
; OUT: SP + 0 = 1 si c'est une lettre minuscule
;           A = 0 sinon
;
isLetter:SUBSP   2,i         ; #iLsavX
         STX     iLsavX,s    
         LDX     0,i         
         STX     iLOut,s     
         CPA     'a',i       
         BRLT    iLFin       
         CPA     'z',i       
         BRGT    iLFin       
         LDX     1,i         
         STX     iLOut,s     
iLFin:   LDX     iLsavX,s    
         RET2                ; return ( c >= 'a' && c <= 'z' )  #iLsavX
iLsavX:  .EQUATE 0           ; #2h tampon pour X
iLOut:   .EQUATE 4           ; #2h valeur de retour
;
; Sous-programme utilitaire affichant à l'écran un espace, le nombre d'occurrences
; du noeud passé en paramètre puis un saut de ligne.
;
;  IN : X : Adresse du noeud dont on veut afficher le nombre d'occurrence
;  OUT: pas de sortie
;
affOccur:CHARO   ' ',i       ;Pep8.charo(' ');
         DECO    nNumber,x   ;Pep8.deco(noeud.number);
         CHARO   '\n',i      ;Pep8.charo('\n');
         RET0                
;
; Sous-programme qui lit tous les espaces et renvoie le premier caractère
; qui n'est pas un espace.
;
;  IN : A : Le caractère saisi
;  OUT : A : Le premier caractère qui n'est pas un espace
;
delSpace:SUBSP   1,i         ; #delChar
delSLoop:CPA     ' ',i       ; while ( c == ' ' ) {
         BRNE    delSpFin    
         CHARI   delChar,s   
         LDA     0,i         
         LDBYTEA delChar,s   ;   c = Pep8.chari();
         BR      delSLoop    ; }
delSpFin:RET1                ; return c; #delChar
delChar: .EQUATE 0           ; #1c le caractère saisi
;
; Sous-programme utilitaire retournant le nombre d'occurrences maximal d'un mot contenu
; dans l'abre passé en paramètre.
;
;  IN : X: adresse la racine de l'arbre à examiner
;  OUT: A: nb de l'occurrence maximale de cet arbre
;
getMax:  SUBSP   6,i         ; #gNoeud #gIndex #gOccur
         STX     gNoeud,s    
         LDA     0,i         
         STA     gOccur,s    ; int occur = 0;
         LDA     nNumber,x 
         CPA     0,i         
         BRLE    getMNext    ; if ( noeud.number > 0 )
         STA     gOccur,s    ;   occur = noeud.number;
getMNext:LDX     0,i         
         STX     gIndex,s    
getLoop: CPX     nTailCh,i   
         BRGE    getFin      ; for ( int i = 0; i < 26; i++ ) {
         STX     gIndex,s    
         LDX     gNoeud,sxf  
         CPX     0,i         
         BREQ    getInc      ;   if ( noeud.child[i] != null )
         CALL    getMax      ;     occurChilds = getMax( noeud.child[i] );
         CPA     gOccur,s    ;     if ( occurChilds > occur )
         BRLE    getInc      
         STA     gOccur,s    ;     occur = occurChilds;
getInc:  LDX     gIndex,s    ;   }
         ADDX    2,i         
         BR      getLoop     ; }
getFin:  LDX     gNoeud,s    
         LDA     gOccur,s    
         RET6                ; return occur;#gNoeud #gIndex #gOccur
gOccur:  .EQUATE 0           ; #2d occurrence du noeud actuel
gIndex:  .EQUATE 2           ; #2d index du tableau de childs
gNoeud:  .EQUATE 4           ; #2h adresse du noeud passé en paramètre
;
; Opérateur NEW
;  IN: A contient le nombre d'octets à allouer
;  OUT: X contient l'adresse mémoire de l'espace alloué
;       A est une valeur quelconque
;
new:     SUBSP   4,i         ;  #newCount    #newPtr
         STA     newCount,s  
         LDX     hpPtr,d     ;returned pointer
         ADDA    hpPtr,d     ;allocate from heap
         STA     hpPtr,d     ;update hpPtr
         STX     newPtr,s    ; newPtr = X
         LDA     newCount,s  ; newCount = A
         LDX     0,i   
; Cette section initialise toute l'espace allouée à 0      
newLoop: CPA     0,i         
         BREQ    newFin      
         STA     newCount,s  
         LDA     0,i         
         STBYTEA newPtr,sxf  
         LDA     newCount,s  
         SUBA    1,i         
         ADDX    1,i         
         BR      newLoop     
newFin:  LDX     newPtr,s    
         RET4                ;  #newCount #newPtr
newPtr:  .EQUATE 0           ; #2h Pointeur vers l'espace à initialisé
newCount:.EQUATE 2           ; #2d Compteur pour la boucle d'initialisation
hpPtr:   .ADDRSS heap        ;address of next free byte
heap:    .BLOCK  1           ;first byte in the heap
         .END                  
