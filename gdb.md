# GDB

Une fois dans gdb :
```bash
layout split 
````
Pour mettre gdb en mode fenêtre avec invité de commande, code en C et en assembleur.
Par défaut, le focus est sur la fenêtre du C mais vous pouvez changer le focus en faisant Ctrl-X puis O jusqu\'à ce que vous ayez le focus ou vous voulez.
Avoir le focus sur l\'invité de commande permet par exemple de remonter dans l\'historique de commandes.
## Commandes utiles
- `si` - Permet de step une instruction en assembleur
- `s` - Permet de step une instruction en C
- `c` - Permet de continuer l\'exécution jusqu\'au prochain breakpoint (ou pour toujours s\'il n\'y a pas de breakpoint)

## Les breakpoints
L\'ajout d\'un breakpoint se fait via la commande `b [...]`.
Il faut remplacer les crochets par l\'endroit ou vous souhaitez mettre le breakpoint. Pour cela plusieurs possibilités :
- Écrire directement le nom de la fonction où vous voulez vous arrêter. Exemple : `b main`
- Écrire le nom du fichier et la ligne du code C où vous voulez placer le breakpoint. Exemple : `b thread.c:118`
- Écrire l\'adresse de l\'instruction en assembleur où vous voulez le breakpoint avec une astérisque. Exemple : `b *0x80000a3c`

Pour supprimer un breakpoint, je sais pas, je les supprime tous via la commande `d` (sorrry).

## L\'affichage
Deux commandes pour afficher des choses : `p` et `x`.
### Print (`p`)
`p` sert à afficher des variables quelconques. Vous pouvez afficher :
- N\'importe quel variable du code C actuellement accessible. Exemple : `p thread->addr`
- N\'importe quel registre du processeur avec un $ devant son nom. Exemple : `p $ra`

Vous pouvez aussi choisir le format d\'affichage de ce que vous allez print. Si vous savez que vous allez voir une adresse utilisez `p/a $ra` par exemple.
Vous pouvez aussi choisir d\'afficher en hexadécimal via `p/x $pc` ou en binaire via `p/t $sp`.

### Afficher le contenu de la mémoire (`x`)
Pour afficher le contenu de la mémoire il suffit d\'utiliser la commande `x` avec l\'adresse que vous voulez voir.<br>
Exemple : `x 0x80000abc`<br>
Vous pouvez aussi spécifier que vous voulez voir plusieurs adresses consécutives d\'un coup en ajoutant un nombre après le `x` et son unité : 
- `x/16b` affiche 16 octets
- `x/32h` affiche 32 demi-mots (1 demi-mot = 2 octets)
- `x/8w` affiche 8 mots (1 mot = 4 octets = 32 bits)

Vous pouvez aussi utiliser les formateurs de la commande `p` comme `a`, `x` et `t`. Ils ont le même effet mais il faut les placer entre le nombre et l\'unité.<br>
Exemple : `x/16xb 0x80000abc` affichera 16 octets de mémoire en hexadécimal en partant de l\'adresse `0x80000abc`.

### Info (`i`)
La commande `i` permet d\'afficher des informations sur plusieurs sujets. Je ne m\'en sert que pour faire :
- `i all-r` pour afficher le contenu de TOUS les registres (y compris ceux du CSR ...).
- `i registers` ou `i r` affiche le contenu des registres "normaux".

Voilà voilà, have fun.
