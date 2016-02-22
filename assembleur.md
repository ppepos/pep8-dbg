# References d'assembleurs

## Exemple en python

[Python example](http://inst.eecs.berkeley.edu/~cs61c/fa13/proj/04/assembler.py)

Se fait un deux passes:

 1. Les labels
 2. Assemblage des instructions

Toute avec des regex.

## Powerpoint sur differents design possibles

[PPT](http://www.google.ca/url?sa=t&rct=j&q=&esrc=s&source=web&cd=9&ved=0ahUKEwiaxfOz14TLAhWGqB4KHSqDDUoQFghQMAg&url=http%3A%2F%2Fstaff.csie.ncu.edu.tw%2Fchia%2FCourse%2FSP%2Fsec2-4.ppt&usg=AFQjCNHJn6UjDE7np3y4Eb2hCjAd8nEcpg&sig2=ElKj4iYWddGtVcV47SNbBg&cad=rja)

# Pepperdine Specs

* Instructions sur 8 bits + operande(s): Soit 1 octet ou 3 octets (sauf pour les instructions de reservation d'espace
	memoire)
* Labels a gerer
* commentaires

## Proposition

 * Passe 1 : lire les lignes et ramasser les labels
 * Passe 2 : Remplacer les labels et generer les opcodes pour les instr



