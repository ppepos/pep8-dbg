# Recherche concernant le débogguage à reculons

## Articles

### AKGUL, MOONEY et PANDE : A fast assembly level reverse execution method via dynamic slicing (2004)

- Dynamic slicing: Isolation dynamique des parties d'un programme qui affectent une zone mémoire/variable 
- Reverse code execution (RCG) algorithm : Algo qui crée le programme inverse et n'a donc pas besoin de garder un ensemble d'états.  Il y a néanmoins de la sauvegarde d'états dans certains cas.
- Ils ajoutent le dynamic slicing au RCG
- L'apport de leur recherche est d'accélérer RCG via dynamic slicing et d'améliorer le dynamic slicing.
- Avant leur papier, le dynamic slicing se faisait lors de l'exécution. Leur papier présente une façon de faire le dynamic slicing durant l'exécution inverse à l'aide de prédicats dans le programme inverse.


### THOSHIHIKO KOJU et al.: An efficient and generic reversible debugger using the virtual machine based approach

- Cherchent à pallier aux problèmes de compatibilité et d'efficacité des travaux précédents en debogguant dans une machine virtuelle
- Leur solution permet d'exécuter le programme sur un vrai CPU ou dans une machine virtuelle
- Puisque les techniques utilisées pour permettre le reverse execution ont chacun leurs avantages et inconvénients, ils proposent d'inclure ces options dans leur outil et de laisser le choix à l'utilisateur. (vitesse d'exécution, consommation mémoire, granularité des unités d'exécution inverse, etc.)
- Deux approches pour la sauvegarde des états :
	- static instrumentation approach : ajouter des instructions au codes pour sauvegarder les états juste avant d'exécuter le programme
	- virtual machine based approach : la machine virtuelle est responsable de la sauvegarde des états (beaucoup plus flexible)
- Deux outils précédents : PROVIDE et LVM
- PROVIDE ne gère qu'un sous-ensemble de C
- LVM nécessite de tout recompiler les librairies avec le Leonardo C Compiler
- Les deux options interprètent le code, ce qui vient avec un overhead à l'exécution

- Compatibilité : Leur VM exécute du code machine
- Efficacité : Ils font du dynamic translation. La VM ajoute du code au programme pour sauvegarder les états, le tout en langage machine. Donc, c'est toujours le CPU qui exécute directement le programme.
- On peut changer du mode natif au mode VM en pleine exécution, ce qui permet également de s'attacher à un processus. En mode natif, on n'a pas accès aux fonctionnalités de reverse debugging, mais dès qu'on passe en move VM, le reverse debugging devient possible.




### ALTEKAR et STOICA : Output-Deterministic Replay for Multicore Debugging (2009)

- Contexte multi-thread
- Parvenir à rejouer des cas de race condition
- Deterministic-Run Inference : Prendre le résultat final et rejouer l'ensemble des chemins possibles pour arriver à ce résultat
