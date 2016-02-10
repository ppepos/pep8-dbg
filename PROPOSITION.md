# Introduction

Une grande partie du travail d'un développeur est d'effectuer le débogage des 
programmes. La plupart du temps, le développeur doit relancer plusieurs fois
l'application avant de trouver la cause du bogue. Si le développeur avait accès
à un débogueur qui lui permettait d'effectuer une exécution inverse, sa
productivité globale augmenterait. Ce constat est également vrai dans un
contexte de sécurité informatique où un développeur cherche à profiter d'un 
faille de sécurité dans un logiciel pour suivre le déploiement de son code 
injecté dans la mémoire du programme. C'est pour répondre à ces deux besoins
que nous avons décidé d'élaborer un projet de déboguage à reculons. L'aspect
sécurité informatique nécessite que nous utilisions un langage très bas niveau.
Puisque le langage assembleur PEP8 est enseigné à l'Université du Québec à
Montréal et que ce language ne possède qu'un ensemble d'instruction très
simple, il est un candidat idéal pour développer notre projet dans le cadre
d'un cours de maîtrise.


# Présentation du projet


# Échéancier


# Revue de littérature

En effectuant notre revue de littérature sur les sujet, nous avons d'abord
remarqué qu'il s'agit d'un sujet qui intéresse les chercheurs en informatiques
depuis des décennies. Nous présentons les trois articles qui présentent les
trois techniques les plus utilisées afin d'effectuer du déboguage à reculons.


Dans son article *Efficient Algorithms for Bidirectional Debugging*, Boothe
présente une approche qui part du constat qu'un appel au débogueur via un *trap*
coûte environ un million de cycles processeur. Il cherche donc à éviter le plus
possible d'effectuer des interruptions. Au lieu d'injecter des interruptions
dans le programme invité, Boothe ajoute des appels à des fonctions qui vont
s'occupper de mettre à jour des compteurs qui vont permettre d'arrêter
l'exécution du programme exactement là où l'utilisateur le désire. Cette
technique est particulièrement efficace lorsqu'un utilisateur voudra arrêter le
programme après un certain nombre d'itérations dans une boucle ou bien à une
certain profondeur de récursion, car les débogueurs font se travail en
effectuant des appels au débogueur pour chaque itération dans la boucle. Cette
importante économie en cycle de processeur permet d'effectuer le déboguage à
reculons en réexécutant le programme, parfois même en plus d'une passe, pour
arrêter l'exécution là où l'utilisateur l'a demandé. Afin de s'assurer du
déterminisme de l'exécution, des captures doivent être effectuées dans le cas de
certains appels systèmes. L'approche de Boothe se base donc sur la réexécution
du programme afin de revenir à un état précédent de l'exécution du programme.







