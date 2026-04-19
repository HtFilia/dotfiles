# 🎓 Masterclass — Partie 1/4 : Shell & Navigation

> Ton nouveau shell Zsh + tous les outils CLI modernes. À lire une fois, puis à garder en reference pour les raccourcis qu'on oublie.

## Table des matières

1. [Zsh — les bases qui changent tout](#zsh)
2. [Starship — lire ton prompt](#starship)
3. [Zoxide — le cd intelligent](#zoxide)
4. [fzf — le fuzzy finder qui va transformer ta vie](#fzf)
5. [eza — ls moderne](#eza)
6. [bat — cat avec du style](#bat)
7. [fd — find réécrit](#fd)
8. [ripgrep (rg) — grep ultra rapide](#ripgrep)
9. [atuin — historique shell synchronisé](#atuin)
10. [direnv — environnements par projet](#direnv)

---

## <a name="zsh"></a>1. Zsh — les bases qui changent tout

Tu étais probablement sur bash. Voici ce qui change **immédiatement** en passant à zsh :

### Autosuggestions (le fantôme gris à droite)

Commence à taper une commande et tu vois apparaître, en gris clair, la suite suggérée d'après ton historique :

```
❯ git com▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
       git commit -m "fix bug"   ← en gris
```

- **`→`** (flèche droite) ou **`End`** : accepte toute la suggestion
- **`Ctrl-→`** ou **`Alt-f`** : accepte **mot par mot**
- **`Ctrl-g`** : rejette la suggestion

C'est le truc le plus addictif du setup. Tes commandes longues que tu tapes souvent deviennent 2 touches.

### Syntax highlighting en temps réel

Quand tu tapes une commande :
- Commande valide → **vert**
- Commande inexistante → **rouge**
- Chaîne entre guillemets → **jaune**
- Options (`--flag`) → couleur distincte

Ça te fait gagner du temps avant même d'appuyer sur Entrée : tu vois tes fautes de frappe.

### Autocomplétion intelligente

- **`Tab`** : complète (comme bash)
- **`Tab Tab`** : si plusieurs options, affiche un menu **navigable avec les flèches**
- Fautes de casse ignorées : `cd docu` → complète `Documents`
- Complétion dans le milieu des mots : `vim **co** Tab` peut compléter vers `commit`

### cd qui ne demande pas `cd`

Configuré chez toi par l'option `AUTO_CD` :

```bash
❯ Documents     # équivaut à: cd Documents
❯ ..            # équivaut à: cd ..
```

Et **`-`** tout seul te ramène au dossier précédent :

```bash
❯ cd /tmp
❯ cd ~/projects
❯ -              # retour à /tmp
```

### Pile de dossiers (pushd/popd automatique)

L'option `AUTO_PUSHD` garde un historique de tes `cd`. Pour voir la pile :

```bash
❯ dirs -v
0  ~/projects/api
1  ~/Documents
2  /tmp
```

Et tu sautes :

```bash
❯ cd -1          # va à l'entrée #1 (Documents)
```

### Les alias installés pour toi

Tape-les quand tu veux voir ce qui tourne :

```bash
❯ alias              # toutes les aliases Zsh
❯ alias | grep git   # seulement celles qui parlent de git
```

Les plus utiles à connaître par cœur :

| Alias | Équivalent | Usage |
|---|---|---|
| `ll` | `eza -l --icons --git` | Listing détaillé |
| `la` | `eza -la --icons --git` | Listing complet (cachés inclus) |
| `lt` | `eza --tree --level=2` | Arbre 2 niveaux |
| `..` / `...` / `....` | `cd ..` etc | Remonter de N niveaux |
| `g` | `git` | Ouais, rien que `g status` marche |
| `gs` | `git status -sb` | Status court + branche |
| `gl` | `git log --graph --oneline` | Graph joli |
| `d` | `docker` | |
| `dc` | `docker compose` | |
| `lg` | `lazygit` | |

### Recharger sans redémarrer

Après avoir modifié une config :

```bash
❯ reload         # alias pour `source ~/.zshrc`
# ou
❯ exec zsh       # réexécute zsh dans le même terminal
```

---

## <a name="starship"></a>2. Starship — lire ton prompt

Ton prompt en 2 lignes, qui te dit plein de choses. Voici comment le lire :

```
╭─ 🍎  @fibomac in …/dotfiles on  master ⇡1
╰─❯
```

- **╭─ / ╰─** : décoration, juste pour que les 2 lignes soient visuellement reliées
- **🍎** : icône qui change selon ton OS (macOS, Debian, Arch…)
- **`@fibomac`** : ton hostname (n'apparaît que sur les machines pro ou en SSH, pas obligatoire)
- **`in …/dotfiles`** : ton répertoire courant, **tronqué** avec `…/` pour garder la ligne courte
- **`on  master`** : branche git courante, l'icône  c'est celle de git
- **`⇡1`** : tu as 1 commit local en avance sur le remote
- **`❯`** : le curseur. **Vert** = dernière commande OK. **Rouge** = dernière commande a failli (exit code ≠ 0)

### Autres symboles que tu verras

| Symbole | Signification |
|---|---|
| `⇡N` | N commits à pusher |
| `⇣N` | N commits à puller |
| `⇕⇡N⇣M` | Tu as divergé (rebase/merge nécessaire) |
| `!N` | N fichiers modifiés non stagés |
| `+N` | N fichiers stagés |
| `?N` | N fichiers non trackés |
| `\$` | Tu as un stash |
| `=` | Il y a un conflit de merge |
| `via  3.12` | Tu es dans un venv Python 3.12 |
| `via  1.21` | Projet Go |
| `via  1.75` | Projet Rust |
| `took 3s` | La dernière commande a pris plus de 2 secondes |

### Pourquoi "via" ?

Starship détecte automatiquement les fichiers du projet (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`…) et affiche la version du runtime utilisée **dans ce dossier**. Tu sais instantanément si tu es sur le bon python.

---

## <a name="zoxide"></a>3. Zoxide — le cd intelligent

**Le concept** : zoxide apprend où tu vas. Plus tu visites un dossier, plus il devient facile d'y aller depuis n'importe où.

Dans ton setup, `cd` a été **remplacé** par zoxide (via `zoxide init --cmd cd`). Donc tout ce qui suit utilise juste `cd`.

### Utilisation de base

```bash
# Première fois : navigation normale
❯ cd ~/Documents/apps/dotfiles

# Plus tard, depuis N'IMPORTE OÙ :
❯ cd dotfiles
# zoxide te téléporte directement à ~/Documents/apps/dotfiles

# Encore plus court, avec un bout du chemin :
❯ cd apps dot     # matche "apps" ET "dot" dans le chemin
```

### Le menu interactif (très puissant)

```bash
❯ cdi             # "cd interactive"
```

Ouvre un fuzzy finder avec tous les dossiers connus, triés par "fréquence × récence". Tu tapes 2 lettres, tu vois le match en live, Entrée → tu y es.

### Voir ce que zoxide sait

```bash
❯ zoxide query -l      # liste tous les dossiers mémorisés, triés par score
❯ zoxide query -l -s   # avec les scores
```

### Oublier un dossier

```bash
❯ zoxide remove ~/old/project
```

### Règle d'or

La 1ère fois tu tapes le chemin complet. Ensuite tu tapes juste 3 lettres qui matchent. Au bout de 2 semaines tu navigues dans 50 projets sans jamais retaper un chemin complet.

---

## <a name="fzf"></a>4. fzf — le fuzzy finder qui va transformer ta vie

C'est **le** couteau suisse. Tu peux l'utiliser partout, tout le temps.

### Les 3 raccourcis built-in dans ton shell

| Raccourci | Usage |
|---|---|
| **`Ctrl-T`** | Ouvre un fuzzy finder des fichiers. Sélection → le path est **collé dans ta ligne** |
| **`Ctrl-R`** | Cherche dans ton historique shell (remplacé par atuin, voir plus bas) |
| **`Alt-C`** | Fuzzy finder des dossiers → `cd` direct dedans |

Exemple concret :

```bash
❯ vim <Ctrl-T>
# → menu fzf apparaît avec tous les fichiers, tu tapes "confi", tu vois
#   ~/.config/nvim/init.lua en haut, Entrée → la ligne devient:
❯ vim ~/.config/nvim/init.lua
```

### L'opérateur `**<Tab>`

Dans **n'importe quelle commande**, tape `**` puis `<Tab>` pour invoquer fzf :

```bash
❯ cat **<Tab>           # fuzzy finder pour choisir un fichier
❯ ssh **<Tab>           # fuzzy finder pour choisir un hôte connu
❯ kill -9 **<Tab>       # fuzzy finder sur les processus
❯ git checkout **<Tab>  # fuzzy finder sur les branches
```

### Syntaxe de recherche fzf

Dans n'importe quel prompt fzf tu peux utiliser :

| Pattern | Match |
|---|---|
| `config` | fuzzy : "c" puis "o" puis "n"... dans l'ordre |
| `'config` | match **exact** du mot "config" |
| `^nvim` | commence par "nvim" |
| `lua$` | finit par "lua" |
| `!test` | NE contient PAS "test" |
| `nvim config` | contient "nvim" ET "config" |
| `py$ | lua$` | finit par "py" OU "lua" |

### Les fonctions personnalisées que tu as déjà

Définies dans ton `~/.zshrc` :

```bash
❯ fe              # fuzzy edit : choisir un fichier et l'ouvrir dans nvim
❯ fcd             # fuzzy cd : choisir un dossier et y aller
❯ fga             # fuzzy git add : multi-sélection de fichiers à stager
❯ fkill           # fuzzy kill : choisir un process à tuer (Tab pour multi-sélection)
```

### Un truc de niveau pro

La preview window : la plupart des commandes fzf dans ton setup ont une prévisualisation à droite. Dans `fe`, quand tu tapes un fichier dans la liste de gauche, tu vois son contenu colorisé à droite. Tu peux :

- **`Ctrl-/`** : toggle la preview on/off
- **`Ctrl-↑ / Ctrl-↓`** : scroller la preview sans perdre la sélection

---

## <a name="eza"></a>5. eza — ls moderne

Remplace `ls` avec icônes, couleurs, info git.

### Usage au quotidien

```bash
❯ ls                     # listing simple avec icônes
❯ ll                     # listing long (taille, date, propriétaire) + statut git
❯ la                     # pareil + fichiers cachés
❯ lt                     # arbre 2 niveaux
❯ ltt                    # arbre 3 niveaux
```

### Options à connaître

```bash
❯ eza -l --git           # colonne avec le statut git (M modified, N new...)
❯ eza --tree --level=3 --git-ignore   # arbre en respectant .gitignore
❯ eza -l --sort=size --reverse        # tri par taille décroissante
❯ eza -l --sort=modified              # tri par date de modif
❯ eza -l --total-size                 # taille cumulée des dossiers (lent mais utile)
```

### Filtrer

```bash
❯ eza -l *.md            # glob standard zsh
❯ eza --git-ignore       # ignore ce qui est dans .gitignore
❯ eza -D                 # seulement les dossiers
❯ eza -f                 # seulement les fichiers
```

---

## <a name="bat"></a>6. bat — cat avec du style

`cat` qui affiche avec syntax highlighting, numéros de ligne, et intégration git (montre les modifs non commitées en marge).

### Usage de base

```bash
❯ cat fichier.py         # (c'est un alias vers bat --paging=never)
❯ bat fichier.py         # avec pagination si le fichier est long
❯ bat -p fichier.py      # mode "plain" : pas de numéros, pas de frame
❯ bat -n fichier.py      # juste les numéros de ligne
❯ bat -r 10:20 file.py   # lignes 10 à 20 uniquement
```

### Multiple fichiers

```bash
❯ bat file1.py file2.py  # les affiche l'un après l'autre avec headers
```

### Avec des pipes

```bash
❯ curl -s https://api.github.com/users/torvalds | bat -l json
❯ echo 'SELECT * FROM users' | bat -l sql
```

### Thèmes

```bash
❯ bat --list-themes                       # liste
❯ bat --theme="Tokyo Night" fichier.py    # change ponctuellement
```

(Ton thème par défaut est déjà Tokyo Night via la config.)

### Astuce : utiliser bat comme help pager

Dans le `.zshrc` je t'ai configuré `MANPAGER` pour que `man <cmd>` passe par bat. Donc les man pages sont colorisées. Essaie :

```bash
❯ man grep               # tu vois les sections en couleur
```

---

## <a name="fd"></a>7. fd — find réécrit

Trouve des fichiers, mais saine d'esprit. 10× plus simple que `find` pour 95% des usages.

### Syntaxe qui claque

```bash
❯ fd config              # cherche "config" dans les noms, partout sous ./
❯ fd '\.py$'             # tous les .py (regex si on veut)
❯ fd -e py               # tous les .py (plus simple)
❯ fd config ~/.config    # cherche dans un dossier spécifique
```

### Par défaut, fd respecte

- `.gitignore` → ignore les `node_modules/`, `target/`, `__pycache__/`...
- `.ignore` → pareil mais pour fd spécifiquement
- Fichiers cachés ignorés

Pour outrepasser :

```bash
❯ fd -H config           # inclut les fichiers cachés
❯ fd -I config           # ignore le .gitignore
❯ fd -HI config          # les deux
```

### Les options les plus utiles

```bash
❯ fd -t f                # seulement fichiers (type file)
❯ fd -t d                # seulement dossiers
❯ fd -t l                # seulement symlinks
❯ fd -d 2                # profondeur max 2 niveaux
❯ fd -s Config           # case-sensitive (par défaut c'est case-insensitive)
❯ fd --changed-within 1d # modifiés dans les dernières 24h
❯ fd --size +10M         # plus de 10 Mo
```

### Exécuter une commande sur les résultats

```bash
❯ fd -e py -x wc -l              # compte les lignes de chaque .py
❯ fd -e log -x rm                # supprime tous les .log
❯ fd old_name new_name -x mv {} {.}  # renommage en masse
```

Le `{}` est remplacé par chaque match, `{.}` par le match sans extension.

### Avec fzf

```bash
❯ fd -e py | fzf --preview 'bat --color=always {}'
# liste tous les py, avec preview bat
```

---

## <a name="ripgrep"></a>8. ripgrep (rg) — grep ultra rapide

Cherche **dans le contenu** des fichiers, pas dans les noms (c'est fd pour ça).

### De base

```bash
❯ rg "TODO"                   # cherche TODO partout sous ./
❯ rg "TODO" src/              # limité à src/
❯ rg -i "todo"                # case-insensitive
❯ rg -w "bar"                 # mot entier (pas "bar" dans "baryton")
```

### Filtres par type

```bash
❯ rg --type py "import requests"      # que dans les .py
❯ rg --type-not test "TODO"           # partout sauf dans les tests
❯ rg --type-list                      # voir tous les types connus
```

Aliases courts : `-t py`, `-T test`.

### Contexte autour du match

```bash
❯ rg -A 3 "error"             # 3 lignes Après le match
❯ rg -B 3 "error"             # 3 lignes avant
❯ rg -C 3 "error"             # 3 lignes des deux côtés
```

### Remplacer (en preview)

```bash
❯ rg "old_name" -r "new_name"     # affiche ce qui serait remplacé, SANS écrire
# Pour vraiment écrire : passe par sed ou un éditeur
```

### Régex avancé

```bash
❯ rg "def \w+\("              # match "def suivi d'un nom de fonction("
❯ rg -P "(?<=def )\w+"        # lookbehind (nécessite -P : PCRE)
```

### Seulement les fichiers contenant

```bash
❯ rg -l "FIXME"               # liste les fichiers contenant FIXME (sans les lignes)
❯ rg --files-without-match "FIXME"  # au contraire
```

### Compter

```bash
❯ rg -c "TODO"                # nombre de matches par fichier
❯ rg --count-matches "TODO"   # total (pas par fichier)
```

### Le combo ultime : rg + fzf + bat

```bash
❯ rg --vimgrep "error" | fzf --preview 'bat --color=always {1} --highlight-line {2}'
# Cherche "error", fzf pour sélectionner le résultat, preview avec la ligne mise en valeur
```

C'est exactement ce que LazyVim fait en interne pour son "live grep".

---

## <a name="atuin"></a>9. atuin — historique shell synchronisé

Ton historique shell, mais en base SQLite, avec beaucoup plus de contexte (dossier, hostname, exit code, durée).

### Le raccourci principal : Ctrl-R

Dans atuin, `Ctrl-R` ouvre une UI plein écran :

```
❯ [Ctrl-R]

  > git com                                              142 results

    git commit -m "feat: add x"    ~/projects/api        3 days ago   0ms
    git commit --amend              ~/projects/api        5 days ago   0ms
    git commit -m "fix: typo"       ~/dotfiles            1 week ago   0ms
```

Tu tapes, ça filtre en fuzzy sur **toutes tes machines** (si tu as activé la sync).

### Navigation dans l'UI

- **`↑↓`** : parcourir les résultats
- **`Tab`** : **copier** la commande dans la ligne (édition avant exécution)
- **`Entrée`** : exécuter immédiatement
- **`Ctrl-C`** ou **`Esc`** : annuler
- **`Ctrl-R`** (encore) : cycler entre les modes de recherche (global / dossier / session)

### Filtres puissants

Dans la barre de recherche atuin, tu peux taper :

```
cwd:~/projects    # uniquement les commandes lancées depuis ce dossier
exit:0            # uniquement celles qui ont réussi
before:yesterday  # avant hier
after:1week       # depuis 1 semaine
```

### Stats

```bash
❯ atuin stats
# Top 10 des commandes que tu tapes le plus
```

Utile pour découvrir quelles commandes aliaser pour gagner du temps.

### Synchronisation entre machines

Par défaut atuin est local. Pour syncer entre ton Mac, tes Debian et ton WSL :

```bash
❯ atuin register -u ton_pseudo -e ton@email.com     # crée un compte
❯ atuin login -u ton_pseudo                          # sur les autres machines
❯ atuin sync                                         # force une sync
```

Les données sont chiffrées end-to-end avec une clé générée localement. Le serveur atuin ne voit pas tes commandes en clair.

### Import

Première install : importe ton historique existant :

```bash
❯ atuin import auto       # détecte ton shell et importe tout
```

---

## <a name="direnv"></a>10. direnv — environnements par projet

**Le concept** : tu crées un fichier `.envrc` à la racine d'un projet. Quand tu `cd` dedans, ton shell charge automatiquement des variables d'env, des venv Python, etc. Quand tu `cd` ailleurs, tout est déchargé.

### Exemple le plus simple

```bash
❯ cd ~/projects/api
❯ echo 'export DATABASE_URL="postgres://localhost/mydb"' > .envrc
❯ direnv allow                # autorise ce .envrc (sécurité)
direnv: loading ~/projects/api/.envrc
direnv: export +DATABASE_URL

❯ echo $DATABASE_URL
postgres://localhost/mydb

❯ cd ..
direnv: unloading
❯ echo $DATABASE_URL
(vide)
```

### Auto-activation d'un venv Python

```bash
❯ cd ~/projects/mon_api
❯ uv venv                     # crée un venv dans .venv/
❯ cat > .envrc <<EOF
source .venv/bin/activate
EOF
❯ direnv allow
```

Maintenant à chaque `cd ~/projects/mon_api`, ton venv s'active automatiquement.

### Layout : le helper magique

direnv fournit des helpers. Les plus utiles :

```bash
# .envrc
layout python3          # crée ET active un venv Python
layout node             # utilise le .nvmrc pour la version node
use flake               # active un flake Nix
```

### Sécurité : pourquoi `direnv allow` ?

Un `.envrc` peut exécuter du shell arbitraire. Si tu clones un repo avec un `.envrc`, direnv le bloque tant que tu n'as pas fait `direnv allow`. **Ne jamais faire `allow` sans lire le fichier.**

### Commandes utiles

```bash
❯ direnv status          # dit si le .envrc courant est actif/autorisé
❯ direnv reload          # force un rechargement
❯ direnv edit            # ouvre le .envrc + allow automatique après save
❯ direnv deny            # révoque l'autorisation
```

---

## 🎯 Workflow type "je commence à bosser"

Voilà ce qu'une journée type ressemble après 1 semaine d'usage :

```bash
# 1. Ouvrir le terminal (tmux lance automatiquement une session)
#    (voir partie 4 sur tmux)

# 2. Sauter dans le projet via zoxide (pas besoin du chemin complet)
❯ cd api

# 3. direnv active ton venv + charge tes variables d'env

# 4. Regarder ce qui a bougé
❯ gs                    # git status court
❯ gl                    # git log graphique

# 5. Trouver un fichier à éditer
❯ fe                    # fuzzy editor

# 6. Chercher dans le code
❯ rg "old_api" -t py    # tous les .py qui contiennent old_api

# 7. Retrouver une commande que tu as tapée il y a 2 jours
❯ [Ctrl-R]              # atuin
```

**Prochaine partie** : git (delta, lazygit), tmux, Neovim/LazyVim.
