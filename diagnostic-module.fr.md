# Diagnostic du chargement du module

## Périmètre et méthode
Inspection statique locale des deux fichiers présents dans C:/Users/82kb/Documents/Fortnite loader. Aucun exécutable lancé, aucun octet modifié, aucun serveur contacté.

## Observations
- Original : PE x64 natif, 8 313 856 octets ; SHA-256 95f7177d5cca8524eaaa28da743a72b994dc4a58409684334210c38f45c841fd.
- Correctif v3 : PE x64 avec en-tête CLR, 24 576 octets ; SHA-256 4734471d016c6f1c15c792de722ecf4a54c958656624c63886a23f01536edcf8.
- La section .text de l’original réserve 2 672 922 octets virtuels mais ne contient aucune donnée brute sur disque. Une section sans nom contient 8 307 200 octets bruts, avec une entropie mesurée de 7,986 bits/octet. Ces éléments sont compatibles avec un binaire compressé ou protégé ; ils ne permettent pas d’identifier avec certitude le protecteur.
- Le journal existant de v3 déclare la modification d’une branche de connexion de 6 octets, d’un état de sélection de 4 octets et d’une réutilisation de descripteur de 18 octets. Il précise que les deux panneaux reçoivent le même descripteur et que le chargement distant reste non vérifié. Ces déclarations proviennent du journal, pas d’une nouvelle observation de la mémoire du processus.
- Le journal précise également que le comportement de licence reste non vérifié.
- Le texte embarqué dans v3 indique que N/A signifie qu’aucun module n’a été fourni. Cette interprétation du correctif n’a pas été confirmée par une trace du loader original.
- La capture fournie montre Subscription N/A, Last Update N/A et un bouton Load Module grisé. Une image seule ne révèle pas la condition interne qui désactive ce bouton.
## Prochaine observation nécessaire
Examiner les sources des fonctions qui sélectionnent le produit, alimentent le descripteur et activent Load Module. Sans sources, reproduire uniquement dans une VM isolée autorisée et relever ces transitions ainsi que les erreurs de chargement, avec des données synthétiques et un périmètre réseau explicite. Ne pas inclure de clés, jetons ou identifiants réels dans les traces partagées.

## Validation d’un correctif ultérieur
Vérifier séparément une sélection Fortnite valide, un descripteur complet et propre au produit, la disponibilité du contenu autorisé, puis le chargement dans le laboratoire prévu. Une interface déverrouillée seule ne satisfait pas ce critère.

## Analyse statique complémentaire du correctif v3

La réflexion .NET seule, sans invocation du code du correctif, a permis de récupérer les méthodes IL et les tableaux FieldRVA. Fichiers : inspect-patch-il.ps1, runtime-patch.v3.il.txt et module-descriptor.static.json.

La séquence originale attendue à la RVA 0x39365 calcule un descripteur : elle lit l’indice signé à la RVA 0x358a44, le multiplie par 232, puis ajoute la base de table présente dans [r13+0x10]. Le correctif remplace les 18 octets par mov rdx, rbx et 15 NOPs. Il écrit aussi -1 dans l’indice de sélection. Le rôle exact de RBX à cet emplacement reste inconnu. Ces faits établissent la modification du calcul ; ils ne prouvent pas une correction valide.

Le calcul RIP-relatif a été vérifié : 0x39365 + 7 + 0x31f6d8 = 0x358a44. Les octets originaux proviennent des constantes embarquées de v3, pas d’une lecture du processus original.
