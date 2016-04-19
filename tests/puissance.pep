;
;  @author : Frédéric Vachon
;
;  @version : 2013-11-06
;
;  Description du programme :
;
;	Ce programme permet à deux joueurs de s'affronter dans une partie du
;	jeu Puissance 4. Le jeu se joue dans une grille de jeu 6 par 7. Chaque
;	joueur place alternativement un jeton dans la grille et chaque jeton se
;	dépose dans la plus basse rangée disponible.
;
;  Victoire :
;
;	Pour gagner, un joueur doit aligner 4 pièces horizontalement, verticalement
;	ou en diagonale. Si un joueur met une pièce dans une colonne qui est déjà
;	pleine, il perd. Il y a partie nulle si la grille de jeu est pleine.
;
;  Commandes :
;
;	1 à 7 : dépose une pièce dans la colonne appropriée.
;	d : affiche la grille de jeu et le nom du joueur à qui c'est le tour.
; 	q : Quitte le programme.
;
;  LIMITES : Ce programme fonctionne seulement avec une table de jeu de 6x7 
;            ( 6 lignes et 7 colonnes )
;
         NOP0                ; do {
loop:    CHARI   in,d        ;     in = lireChar();
         LDA     0,i         ;
         LDBYTEA in,d        
         CPA     'd',i       
         BREQ    affiche     
         CPA     'q',i       
         BREQ    fin         
         CPA     '1',i       
         BRLT    loop        
         CPA     '7',i       
         BRLE    ifNumber    ;   }
         BR      loop        ;   while ( in != 'd' && in != 'q' && ( in < '1' || in > '7' ) );
ifNumber:NOP0                ;   if ( in >= '1' && in <= '7' )
         SUBA    0x0031,i    
         STA     colonne,d   ;     colonne = in - 0x30 // Conversion du char vers un int
         LDX     35,i        ;
         ADDX    colonne,d   
         LDA     0,i         
         LDBYTEA jeu,x       
         CPA     0,i         ;     if ( jeu[5][colonne] == 0x00 ) {
         BRNE    deborde     
         LDX     colonne,d   
         STA     ligne,d     
loop2:   LDA     0,i         ;       do {
         LDBYTEA jeu,x       ;
         CPA     0,i         ;
         BREQ    addJeton    ;         if ( jeu[ligne][colonne] != 0x00 ) {
         ADDX    nbColonn,i  ;           ligne++;
         LDA     ligne,d     
         ADDA    1,i         
         STA     ligne,d     
         BR      loop2       ;
addJeton:LDA     0,i         ;         } else {
         LDBYTEA player,d    ;           jeu[ligne][colonne] = player;
         STBYTEA jeu,x       ;           place = true;
         NOP0                ;         }
         NOP0                ;       } while ( !place );
; SECTION TESTS POUR LA VICTOIRE
         LDX     colonne,d   
         CALL    winC        ;       if ( winC()
         CPA     1,i         
         BREQ    victoire    
         LDX     ligne,d     
         CALL    winR        ;          || winR()
         CPA     1,i         
         BREQ    victoire    
         LDA     colonne,d   
         LDX     ligne,d     
         CALL    winD1       ;          || winD1()
         CPA     1,i         
         BREQ    victoire    
         LDA     colonne,d   
         LDX     ligne,d     
         CALL    winD2       ;          || winD2() ) {
         CPA     1,i         
         BREQ    victoire    ;             GOTO victoire
         CALL    nulle       ;       } else if ( nulle() ) {
         CPA     1,i         ;
         BREQ    estNulle    ;            GOTO estNulle }
; CHANGEMENT DE JOUEUR
         LDA     0,i         
         LDBYTEA player,d    
         CPA     'X',i       ;       if ( player == 'O' ) {
         BREQ    chanplay    ;         player = 'X';
         LDBYTEA 'X',i       ;       } else {
         STBYTEA player,d    ;         player = 'O';
         BR      loop        ;       }
chanplay:LDBYTEA 'O',i       
         STBYTEA player,d    
         BR      loop        
; DÉBORDEMENT
deborde: LDA     0,i         ;     } else {
         LDBYTEA player,d    
         LDX     colonne,d   
         ADDX    1,i         
         STBYTEA linDebor,x  ;       linDebor[colonne + 1] = player;
         STRO    linDebor,d  ;       println(linDebor);
         CHARO   '\n',i      
         CALL    affi        ;       affi();
         STRO    msgBase,d   
         CHARO   player,d    
         STRO    msgDebor,d  ;       print("Le joueur " + player + " perd.");
         STOP                ;       Pep8.stop();
         NOP0                ;     }
affiche: CALL    affi        ;   } else if ( in == 'd' ) {
         STRO    msgTour1,d  ;     affi();
         CHARO   player,d    
         STRO    msgTour2,d  ;     println("Au joueur " + player + " de jouer.");
         CHARO   '\n',i      ;   }
         BR      loop        ; while ( in != q && !victoire && !debordement && !nulle );
estNulle:CALL    affi        ;
         STRO    msgNulle,d  
         STOP                ; print("Partie nulle.");
victoire:CALL    affi        
         STRO    msgBase,d   
         CHARO   player,d    
         STRO    msgWin,d    
fin:     STOP                
;
; AFFICHE LA TABLE DE JEU
;
; Paramètres :
;   Aucun
; Retour  :
;   Aucun
;
affi:    LDX     0,i         
         LDA     nbColonn,i  
         LDX     nbLigne,i   
         CALL    mult        
         STX     affiMax,d   ; affiMax = nbColonn * nbLigne
         SUBX    nbColonn,i  
affiFor1:NOP0                ; for (int i = nbLigne - 1; i >= 0; i--) {
         CHARO   ':',i       ;   print(':');
affiFor2:LDA     0,i         ;   for (int j = 0; i < nbColonne; i++) {
         LDBYTEA jeu,x       ;     if ( jeu[i][j] == 0 )
         CPA     0,i         ;
         BRNE    affiChar    
         CHARO   ' ',i       ;       print(' ');
         BR      affiSpac    ;     else
affiChar:CHARO   jeu,x       ;       print(jeu[i][j])
affiSpac:ADDX    1,i         
         CPX     affiMax,d   ;
         BRLT    affiFor2    ;  }
         CHARO   ':',i       ;
         CHARO   '\n',i      ;  println(':');
         SUBX    nbColonn,i  
         STX     affiMax,d   
         SUBX    nbColonn,i  
         CPX     0,i         
         BRLT    affiFin     
         BR      affiFor1    ; }
affiFin: RET0                
affiMax: .WORD   0           
;
;
;
; VÉRIFIE VICTOIRE PAR COLONNE
;
; Paramètres :
;   X : numéro de colonne à vérifier
;       (0 est la première colonne)
; Retour :
;   A : 1 si victoire
;       0 pas de victoire
;
winC:    LDA     0,i         ; victoire = false
         STA     winCcoun,d  ; winCcoun = 0;
winCloop:CALL comp         ; while (colonne < jeuSize && !victoire) {
         CPA     1, i        ;   if ( jeu[i][colonne] == joueur )
         BRNE    winCnot     
         LDA     winCcoun,d  
         ADDA    1,i         
         STA     winCcoun,d  ;     winCcoun++;
         BR      winCtest    
winCnot: LDA     0,i         ;   else
         STA     winCcoun,d  ;     winCcoun = 0;
winCtest:CPA     4,i         ;   if ( winCcoun >= 4 )
         BRLT    winCinc     
         LDA     1,i         
         BR      winCfin     ;     victoire = true;
winCinc: ADDX    nbColonn,i  
         CPX     jeuSize,i   ;   i++;
         BRLT    winCloop    
         LDA     0,i         
winCfin: LDX     0,i         
         STX     winCcoun,d  ; }
         RET0                
winCcoun:.WORD   0           ; Compteur de jetons
;
;
; VÉRIFIE VICTOIRE PAR LIGNE
;
; Paramètres :
;   X : numéro de la ligne à vérifier
;       (0 est la ligne inférieure)
; Retour :
;   A : 1 si victoire
;       0 pas de victoire
;
winR:    LDA     0,i         
         STA     winRcoun,d  ; winRcoun = 0
         LDA     nbColonn,i  
         ADDX    1,i         
         CALL    mult        
         STX     winRmax,d   ; winRmax = nbColonn * X
         SUBX    nbColonn,i  ; premier index = (nbColonn * X) - nbColonn 
winRloop:CALL comp           ; do {
         CPA 1, i            ;   if ( jeu[ligne][X] == player ) 
         BRNE    winRnot     ;     
         LDA     winRcoun,d  
         ADDA    1,i         
         STA     winRcoun,d  ;     winRcoun++;
         BR      winRtest    
winRnot: LDA     0,i         ;  else
         STA     winRcoun,d  ;    winRcoun = 0;
winRtest:CPA     4,i         ;  if ( winRcoun >= 4 ) 
         BRLT    winRinc     
         LDA     1,i         ;    victoire = true;
         BR      winRfin     
winRinc: ADDX    1,i         ;   X++;
         CPX     winRmax,d   
         BRLT    winRloop    ; } while ( i < winRmax && !victoire );
         LDA     0,i         
winRfin: LDX     0,i         
         STX     winRcoun,d  ; winRcoun = 0;
         RET0                ; return victoire;
winRcoun:.WORD   0           ; #2d Compteur de jetons
winRmax: .WORD   0           ; Indice maximum de la ligne
;
; VÉRIFIE VICTOIRE DIAGONALE COIN BAS GAUCHE
;
; Paramètres :
;   A : numéro de colonne de la diagonale
;       (0 est la première colonne)
;   X : numéro de la ligne de la diagonale
;       (0 est la ligne inférieure)
; Retour :
;   A : 1 si victoire
;       0 pas de victoire
;
winD1:   CPA     0,i         ; while (A != 0 && X != 0 ) {
         BREQ    winD1beg    
         CPX     0,i         
         BREQ    winD1beg    
         SUBA    1,i         ;   A--;
         SUBX    1,i         ;   X--;
         BR      winD1       ; }
winD1beg:STA     winD1ind,d  
         STX     winD1cou,d  
         LDA     nbColonn,i  
         SUBA    winD1ind,d  
         LDX     nbColonn,i  
         CALL    mult        
         STX     winD1max,d  ; winD1max = ((nbColonn - indice colonne) * nbColonn) 
         LDX     winD1cou,d  
         LDA     nbColonn,i  
         CALL    mult        
         ADDX    winD1ind,d  
         STX     winD1ind,d  ; winD1ind = (X * nbColonn) + A
         LDA     0,i         
         STA     winD1cou,d  ; winD1cou = 0;
winD1loo:NOP0                ; do {
         call comp           ;   if ( jeu[X][A] == joueur ) {
         CPA     1, i        
         BRNE    winD1not    
         LDA     winD1cou,d  
         ADDA    1,i         
         STA     winD1cou,d  ;     winD1cou++;
         BR      winD1tes    
winD1not:LDA     0,i         ;   else
         STA     winD1cou,d  ;     winD1cou = 0;
winD1tes:CPA     4,i         ;   if ( winD1cou >= 4 )
         BRLT    winD1inc    
         LDA     1,i         ;     victoire = true;
         BR      winD1fin    
winD1inc:ADDX    nbColonn,i  ;   X++;
         ADDX    1,i         ;   A++;
         CPX     winD1max,d  ; } while (X < nbLigne 0 && A < nbColonn && ! victoire);
         BRLT    winD1loo    
         LDA     0,i         
winD1fin:LDX     0,i         
         STX     winD1cou,d  ; winD1cou = 0;
         RET0                
winD1ind:.WORD   0           ; Index du tableau jeu
winD1cou:.WORD   0           ; Compteur de jetons
winD1max:.WORD   0           ; Index limite de la diagonale
;
; VÉRIFIE VICTOIRE DIAGONALE COIN BAS DROITE
;
; Paramètres :
;   A : numéro de colonne de la diagonale
;       (0 est la première colonne)
;   X : numéro de la ligne de la diagonale
;       (0 est la ligne inférieure)
; Retour :
;   A : 1 si victoire
;       0 pas de victoire
;
; LIMITE : Fonctionne seulement avec un tableau à 7 colonnes
;
winD2:   CPA     6,i         ; while (A != 6 && X != 0 ) {
         BREQ    winD2beg    
         CPX     0,i         
         BREQ    winD2beg    
         ADDA    1,i         ;   A++
         SUBX    1,i         ;   X++
         BR      winD2       ; }
winD2beg:STA     winD2ind,d  
         STX     winD2X,d    
         LDX     nbColonn,i  
         CALL    mult        ;
         STX     winD2max,d  ; winD2max = index de la colonne * nbColonn
         LDA     nbColonn,i  
         LDX     winD2X,d    
         CALL    mult        
         ADDX    winD2ind,d  
         STX     winD2ind,d  ; winD2ind = (X * nbColonn) + A
winD2loo:CALL comp           ; do {
         CPA     1, i        ;   if ( jeu[X][A] == joueur ) 
         BRNE    winD2not    
         LDA     winD2cou,d  
         ADDA    1,i         
         STA     winD2cou,d  ;     winD2cou++;
         BR      winD2tes    
winD2not:LDA     0,i         ;   else
         STA     winD2cou,d  ;     winD2cou = 0;
winD2tes:CPA     4,i         ;   if ( winD2cou <= 4 )
         BRLT    winD2inc    ;     victoire = true;
         LDA     1,i         
         BR      winD2fin    
winD2inc:ADDX    6,i         ;   X++;  
         CPX     winD2max,d  ;   A--;
         BRLE    winD2loo    ; } while ( X < nbLigne && A >= 0 && !victoire );
         LDA     0,i         
winD2fin:LDX     0,i         
         STX     winD2cou,d  ; winD2cou = 0;
         RET0                ; return victoire;
winD2ind:.WORD   0           ; Index du tableau jeu        
winD2cou:.WORD   0           ; Compteur de jetons
winD2max:.WORD   0           ; Index limite de la diagonale
winD2X:  .WORD   0           ; buffer pour mettre la valeur de X (no de colonne)
;
; VÉRIFIE PARTIE NULLE
;
; Retour:
;   A : 1 si la partie est nulle
;       0 sinon
;
nulle:   LDX     jeuSize,i   
         SUBX    nbColonn,i  
nulleLoo:LDA     0,i         
         LDBYTEA jeu,x       ; do {
         CPA     0,i         ;   nulle = true;
         BREQ    nulleNon    ;   if ( jeu[5][i] == ' ' )
         ADDX    1,i         
         CPX     jeuSize,i   ;     nulle = false;
         BRLT    nulleLoo    
         LDA     1,i         
         BR      nulleFin    ; } while ( i < jeu.length && !nulle )
nulleNon:LDA     0,i         
nulleFin:RET0                ; return nulle
;
; MULTIPLICATION
;
; Paramètres :
;   A : opérande 1
;   X : opérande 2
;
; Retour :
;  X = opérande 1 * opérande 2
;
; LIMITE : Prend seulement des nombres positifs
;
mult:    STX     multop1,d   
         LDX     0,i         
multLoop:CPA     0,i         
         BRLE    multFin     
         ADDX    multop1,d   
         SUBA    1,i         
         BR      multLoop    
multFin: RET0              ; return A * X  
multop1: .WORD   0     
;      
; COMPARE UN ÉLÉMENT DU TABLEAU AVEC LE JOUEUR
;
; Paramètres :
;   X : Indice de la table de jeu à vérifier
;
; Retour :
;   A : 1 si pareil
;     : 0 sinon
;
comp:    LDA     0,i         
         LDBYTEA player,d    
         STA     compPl16,d  
         LDBYTEA jeu,x       
         CPA     compPl16,d  ; if ( jeu[X] == player ) 
         BRNE    compNot     
         LDA     1,i         ;   pareil = vrai;
         BR      compFin     
compNot: LDA     0,i         
compFin: RET0                ; return pareil;
compPl16:.BLOCK  2           ; Le joueur codé sur deux octets pour comparaison
;
; Variables globales
;
in:      .BYTE   0           ; Caractère entré par l'utilisateur
colonne: .WORD   0           ; Colonne où a été inséré le jeton
ligne:   .WORD   0           ; Ligne où a été inséré le jeton
jeu:     .BLOCK  42          ; Tableau de la table de jeu
jeuSize: .EQUATE 42          ; Taille du tableau
nbColonn:.EQUATE 7           ; Nombre de colonne du tableau
nbLigne: .EQUATE 6           ; Nombre de ligne du tableau
player:  .BYTE   'X'         ; Joueur à qui c'est le tour de jouer
linDebor:.ASCII  ".       .\x00"
msgTour1:.ASCII  "Au joueur \x00"
msgTour2:.ASCII  " de jouer.\x00"
msgBase: .ASCII  "Le joueur \x00"
msgDebor:.ASCII  " perd.\x00"
msgWin:  .ASCII  " gagne. \x00"
msgNulle:.ASCII  "Partie nulle.\x00   "
         .END                  
