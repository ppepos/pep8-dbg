# Introduction

Une grande partie du travail d'un développeur est d'effectuer le débogage des 
programmes. La plupart du temps, le développeur doit relancer plusieurs fois
l'application avant de trouver la cause du bogue. Si le développeur avait accès
à un débogueur qui lui permettait d'effectuer une exécution inverse, sa
productivité globale augmenterait. Ce constat est également vrai dans un
contexte de sécurité informatique où un développeur cherche à profiter d'une 
faille de sécurité dans un logiciel pour suivre le déploiement de son code 
injecté dans la mémoire du programme. C'est pour répondre à ces deux besoins
que nous avons décidé d'élaborer un projet de débogage à reculons. L'aspect
sécurité informatique nécessite que nous utilisions un langage très bas niveau.
Puisque le langage assembleur *PEP/8* est enseigné à l'Université du Québec à
Montréal et que ce langage ne possède qu'un ensemble d'instruction très
simple, il est un candidat idéal pour développer notre projet dans le cadre
d'un cours de maîtrise.

# Présentation du projet

L'objectif du projet est de développer un débogueur du langage assembleur *PEP/8*.
Le débogueur aura la capacité d'exécuter le programme débogué à sens inverse, ce qui
permettra au programmeur de retracer la provenance des bogues *a posteriori*. Le débogueur
supportera le débogage de code mutant.


Puisque nous ne partons pas d'un projet existant, nous allons devoir
commencer par implémenter un assembleur et un désassembleur. De la sorte, 
un utilisateur pourra fournir un fichier source ou un fichier binaire à l'interpréteur.


Pour réaliser le débogueur, il est impératif de construire un environnement d'exécution de
code machine *PEP/8* qui offre la flexibilité nécessaire pour y ajouter les fonctionnalités de
débogage mentionnées ci-haut. L'interpréteur va effectuer une capture d'informations, lesquelles seront
utilisées par le débogueur afin d'effectuer l'exécution inverse du programme.


Le débogueur fournira les fonctionnalités normales d'un débogueur soit les *breakpoints* et l'exécution
pas-à-pas. Il permettra d'utiliser ces mêmes fonctionnalités en mode d'exécution inverse.  Pour implémenter
cette dernière fonctionnalité, nous allons utiliser une technique de capture d'états se basant sur le maintien
des informations permettant la restitution de l'état précédent l'exécution de chaque instruction. 
Cette implémentation supportera le code auto-modifiant.

# Échéancier

## Pour le 4 mars

* Assembleur
* Desassembleur

## Livrable intermédiaire - 24 mars

* Interpreteur

## Pour le 8 avril

* Debogueur
* Rétro-débogage

## Livrable final - 21 avril

* Perfectionnement et finalisation du projet
* Rédaction du rapport de projet
* Préparer la présentation orale
* Modification de données à la volée (facultatif selon le temps restant)


# Revue de littérature

En effectuant notre revue de littérature sur le sujet, nous avons d'abord
remarqué qu'il s'agit d'un sujet qui intéresse les chercheurs en informatiques
depuis des décennies. Nous présentons les trois articles qui présentent les
trois techniques les plus utilisées afin d'effectuer du débogage à reculons.


Dans son article *Efficient Algorithms for Bidirectional Debugging* (2000), Boothe
présente une approche qui part du constat qu'un appel au débogueur via un *trap*
coûte environ un million de cycles processeur. Il cherche donc à éviter le plus
possible d'effectuer des interruptions. Au lieu d'injecter des interruptions
dans le programme invité, Boothe ajoute des appels à des fonctions qui vont
s'occuper de mettre à jour des compteurs qui vont permettre d'arrêter
l'exécution du programme exactement là où l'utilisateur le désire. Cette
technique est particulièrement efficace lorsqu'un utilisateur voudra arrêter le
programme après un certain nombre d'itérations dans une boucle ou bien à une
certaine profondeur de récursion, car les débogueurs font ce travail en
effectuant des appels au débogueur pour chaque itération dans la boucle. Cette
importante économie en cycle de processeur permet d'effectuer le débogage à
reculons en réexécutant le programme, parfois même en plus d'une passe, pour
arrêter l'exécution là où l'utilisateur l'a demandé. Afin de s'assurer du
déterminisme de l'exécution, des captures doivent être effectuées dans le cas de
certains appels systèmes. L'approche de Boothe se base donc sur la réexécution
du programme afin de revenir à un état précédent de l'exécution du programme.


Akgul propose une autre approche dans son article *Instruction-level Execution
for Debugging* (2002) qu'il améliore par la suite par *dynamic slicing* dans son
article suivant *A Fast Assembly Level Reverse Execution Method via Dynamic
Slicing* (2004). Au lieu d'exécuter le programme de nouveau, il construit le
programme inverse instruction par instruction. De cette façon, il ne faut pas
garder un historique des états d'exécution du programme. Il faut uniquement
pouvoir passer du programme d'origine au programme inverse. Bien entendu, il
doit y avoir capture d'états dans le cas où des appels non déterministes sont
effectués, mais c'est le cas de toutes les approches que nous avons étudiées.


Le troisième article est *An Efficient and Generic Reversible Debugger using the 
Virtual Machine based Approach* (2005) par Koju et al. La technique qu'ils emploient 
se base sur deux modes d'exécution afin de ne pas occasionner de surcoût en
performance pour un utilisateur qui veut exécuter le programme sans effectuer de
débogage. Celui-ci peut changer vers un mode débogage lorsqu'il le souhaite.
Ce qui nous intéresse particulièrement dans cet article est la capture d'états
effectués à intervalle de temps dynamiquement ajusté selon une mesure de la durée 
requise pour la capture d'état et le surcoût toléré. Pour effectuer l'exécution inverse, 
le débogueur retourne au dernier état capturé et réexécute le code jusqu'au point souhaité.

