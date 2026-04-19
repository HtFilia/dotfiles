# 🎓 Masterclass — Partie 2/4 : Git & Édition

> Git en mode pro avec delta et lazygit, tmux qui t'évite d'ouvrir 15 terminaux, et Neovim/LazyVim pour éditer aussi vite que tu penses.

## Table des matières

1. [Les alias git à connaître](#git-alias)
2. [delta — diff qui se lisent](#delta)
3. [lazygit — l'UI terminale qui change tout](#lazygit)
4. [tmux — multiplexer ton terminal](#tmux)
5. [Neovim + LazyVim — l'éditeur keyboard-first](#nvim)

---

## <a name="git-alias"></a>1. Les alias git à connaître

Ta config git est déjà chargée en alias (`git aliases` pour les voir). Voici les plus utiles au quotidien :

### Du shell (dans `~/.zshrc`)

| Alias | Équivalent | Quand |
|---|---|---|
| `g` | `git` | Tout le temps : `g status`, `g log`, etc. |
| `gs` | `git status -sb` | Status court + nom de branche + upstream |
| `ga` | `git add` | Stager un fichier précis |
| `gaa` | `git add --all` | Tout stager |
| `gc` | `git commit` | Commit avec `$EDITOR` pour le message |
| `gcm` | `git commit -m` | Commit one-liner : `gcm "fix: foo"` |
| `gca` | `git commit --amend` | Modifier le dernier commit |
| `gco` | `git checkout` | |
| `gcb` | `git checkout -b` | Créer + bascule sur branche |
| `gb` | `git branch` | |
| `gp` | `git push` | |
| `gpl` | `git pull` | |
| `gl` | `git log --oneline --graph --decorate` | Log compact |
| `gll` | idem + `--all` | Log **de toutes les branches** |
| `gd` | `git diff` | |
| `gds` | `git diff --staged` | Diff de ce qui est prêt à commit |
| `gst` / `gstp` | `git stash` / `git stash pop` | |

### Du git config (alias internes git)

```bash
❯ git s                  # git status -sb
❯ git lg                 # log joli avec couleurs (une ligne par commit)
❯ git lga                # même chose, toutes branches
❯ git last               # détails du dernier commit
❯ git undo               # défait le dernier commit (garde les changements staged)
❯ git amend              # amend sans ré-éditer le message
❯ git br                 # branches triées par date de dernier commit
❯ git cleanup            # supprime les branches locales déjà mergées dans main
❯ git aliases            # liste tous les alias git
```

### Trois comportements que j'ai configurés dans ta git config

1. **`pull.rebase = true`** → `git pull` fait un rebase au lieu d'un merge. Historique plus propre, pas de commits "Merge branch 'main'".

2. **`push.autoSetupRemote = true`** → la première fois que tu pushes une nouvelle branche, pas besoin de `git push -u origin branch`. Juste `gp` et ça crée le tracking automatiquement.

3. **`rebase.autoStash = true`** → si tu as des changements non commités et que tu lances `git pull`, git stash auto → pull → unstash. Plus d'erreur "would be overwritten".

### Le flow commit typique

```bash
❯ gs                     # voir ce qui a bougé
❯ gd                     # voir les diffs non stagés (passe par delta, joli)
❯ gaa                    # tout stager
❯ gds                    # voir ce qu'on s'apprête à commit
❯ gcm "feat: add login"  # commit
❯ gp                     # push
```

---

## <a name="delta"></a>2. delta — diff qui se lisent

delta est un **pager** pour git : il reçoit les diffs git et les ré-affiche en beau. Tu n'appelles jamais `delta` directement. Il est utilisé dès que tu fais `git diff`, `git log -p`, `git show`...

### Ce que tu vois

```
───────────────────────────
api/auth.py
───────────────────────────
   15  │ def login(username, password):
   16  │     user = db.find_user(username)
   17  │     if user is None:
   18  │─        return None
   18  │+        raise AuthError("user not found")
   19  │     return user
```

- Les lignes supprimées ont leur numéro préservé (on voit "ligne 18 avant")
- Les lignes ajoutées sont colorées en vert
- Les numéros de ligne sont affichés (pas en vanilla git)
- Le nom de fichier est dans un header visible
- Si tu es dans un terminal large, tu peux activer le mode **side-by-side**

### Activer le side-by-side ponctuellement

```bash
❯ git diff -- -s         # shortcut pour côte-à-côte
# ou permanent via:
❯ git config --global delta.side-by-side true
```

### Naviguer quand le diff est long

Dans un `git log -p` ou un gros `git diff`, delta est en mode pager. Touches :

- **`n`** : fichier suivant
- **`N`** : fichier précédent
- **`/`** : recherche
- **`q`** : quitter

### Utiliser delta avec autre chose que git

```bash
❯ diff -u file1 file2 | delta     # diff normal, mais avec delta
```

---

## <a name="lazygit"></a>3. lazygit — l'UI terminale qui change tout

C'est **l'outil qui fait gagner le plus de temps** dans ton setup. Au lieu de taper `git add`, `git commit`, `git log`, `git diff`, `git rebase -i`... tu lances une TUI et tout se fait en 1-2 touches.

### Lancer

```bash
❯ lg                 # alias vers lazygit
# ou depuis Neovim : <Space>gg
```

### L'interface, en bref

```
┌──────────────┬────────────────────────────────────────┐
│ 1 Status     │  Diff view (largeur dynamique)         │
│              │                                        │
│ 2 Files      │  def login(u, p):                      │
│              │  -    return None                      │
│ 3 Local Branch│  +    raise AuthError()               │
│              │                                        │
│ 4 Commits    │                                        │
│              │                                        │
│ 5 Stash      │                                        │
└──────────────┴────────────────────────────────────────┘
```

À gauche, 5 panneaux numérotés. À droite, le détail du panneau actif.

### Navigation entre panneaux

- **`1`** à **`5`** : sauter directement à un panneau
- **`←` `→`** ou **`h` `l`** : panneau précédent/suivant
- **`↑` `↓`** ou **`j` `k`** : item précédent/suivant dans le panneau actif
- **`Tab`** : changer d'onglet dans le panneau (ex : "Files" a "Files" et "Submodules")

### Le workflow commit en 5 touches

Tu as modifié 3 fichiers. Tu veux tout commiter.

1. **`lg`** : lance lazygit
2. **`2`** : va dans "Files"
3. **`a`** : stage **all** (ou **`Space`** pour stager un par un)
4. **`c`** : commit → ouvre un prompt pour le message
5. Tape le message, **`Entrée`** → commit fait

Pour pusher : **`P`** (majuscule) depuis n'importe où dans l'UI.

### Les raccourcis à connaître par cœur

Dans **Files** (panneau 2) :

| Touche | Action |
|---|---|
| `Space` | Stage/unstage le fichier |
| `a` | Stage all |
| `A` | **Amend** le dernier commit avec les changements stagés |
| `d` | Discard les changements (attention, irréversible) |
| `s` | Stash |
| `S` | Stash avec options |
| `c` | Commit |
| `C` | Commit en utilisant l'éditeur (pour messages longs) |
| `w` | Commit avec `--no-verify` (skip les hooks) |
| `Entrée` | Entre dans le fichier pour stager ligne par ligne |

Dans **Commits** (panneau 4) :

| Touche | Action |
|---|---|
| `Entrée` | Voir les fichiers de ce commit |
| `d` | Drop (supprime le commit) |
| `e` | Edit (pour rebase -i : marque le commit à éditer) |
| `f` | Fixup (squash sans message) |
| `s` | Squash |
| `r` | Reword (change le message) |
| `p` | Pick |
| `R` | Revert |
| `i` | Interactive rebase depuis **ce commit jusqu'à HEAD** |
| `C` | **Copy** le commit (cherry-pick prep) |
| `V` | **Paste** (cherry-pick le commit copié) |

Dans **Branches** (panneau 3) :

| Touche | Action |
|---|---|
| `Space` | Checkout |
| `n` | **New** : crée une branche depuis la courante |
| `r` | Rebase la branche courante sur celle sélectionnée |
| `M` | Merge la branche sélectionnée dans la courante |
| `d` | Delete |
| `R` | Rename |
| `f` | Fast-forward (pull) |

Dans **Stash** (panneau 5) :

| Touche | Action |
|---|---|
| `Space` | Apply |
| `g` | Pop (apply + delete) |
| `d` | Delete |
| `n` | Nouveau stash (équivaut à `git stash` depuis Files) |

### Rebase interactif sans douleur

Le cas classique : tu as 5 commits "wip", tu veux les squash en 1 propre avant le push.

1. **`lg`**, **`4`** (Commits)
2. Descend sur le 5e commit (le plus ancien de ton travail)
3. **`e`** → marque "edit"
4. Remonte sur les 4 suivants, appuie sur **`f`** pour chacun (fixup)
5. **`m`** → "menu", tu vois "continue rebase"
6. **`Entrée`**

Voilà. Tes 5 commits sont devenus 1. Pas besoin de se rappeler de `git rebase -i HEAD~5`, ni de l'éditeur qui s'ouvre, ni de changer "pick" en "squash" à la main.

### Cherry-pick visuel

1. Dans Commits, appuie sur **`C`** sur le commit à copier (curseur se met en vert)
2. Navigue dans une autre branche (`1` → `g` pour switcher l'onglet vers "Branches", ou depuis Commits sélectionne)
3. Reviens dans Commits
4. **`V`** → cherry-pick

### Autres trucs

- **`?`** à n'importe quel moment : affiche l'aide contextuelle (raccourcis du panneau courant)
- **`x`** : menu d'actions contextuel
- **`q`** : quitter
- **`Esc`** : annule une action en cours
- **`/`** : filtrer dans la liste actuelle
- **`@`** : ouvre un shell dans le repo (pour faire un truc git-inconnu-de-lazygit)

### Config

Le config file de lazygit est à `~/.config/lazygit/config.yml`. Par défaut c'est très bien. Si un jour tu veux changer le thème, c'est là.

---

## <a name="tmux"></a>4. tmux — multiplexer ton terminal

**Le concept** : tmux te permet d'avoir **plusieurs terminaux dans une seule fenêtre**, et de **détacher** ta session pour la retrouver plus tard (même après reboot... bon, presque — voir plus bas).

### Vocabulaire

```
┌───────────────────────────────────────────────┐
│  Session = ensemble de windows                │
│  ┌───────────────────────────────────────┐    │
│  │ Window 1 = "onglet"                   │    │
│  │ ┌─────────────┬───────────────────┐   │    │
│  │ │             │                   │   │    │
│  │ │  Pane 1     │  Pane 2           │   │    │
│  │ │  (split)    │  (split)          │   │    │
│  │ │             │                   │   │    │
│  │ └─────────────┴───────────────────┘   │    │
│  └───────────────────────────────────────┘    │
└───────────────────────────────────────────────┘
```

- **Session** : un groupe de windows, nommé. Souvent 1 par projet.
- **Window** : un "onglet", avec un nom.
- **Pane** : un split dans une window.

### Le prefix : `Ctrl-a`

**Tout** dans tmux commence par appuyer sur `Ctrl-a` (j'ai changé de `Ctrl-b` vers `Ctrl-a`, plus facile à atteindre). On note ça `prefix + X` dans la suite.

### Lancer tmux

```bash
❯ tmux                         # nouvelle session sans nom
❯ tmux new -s api              # nouvelle session nommée "api"
❯ tmux attach                  # réattacher à la dernière session
❯ tmux attach -t api           # réattacher à la session "api"
❯ tmux ls                      # lister les sessions
❯ tmux kill-session -t api     # tuer la session "api"
```

### Le flow type : ouvrir un projet

```bash
❯ cd ~/projects/api
❯ tmux new -s api              # session "api"
# Tu es dans tmux, barre bleue en haut
```

### Créer des splits et windows

Tu veux 3 zones : éditeur à gauche, tests à droite en haut, shell à droite en bas.

```
prefix + |        # split vertical (crée une colonne à droite)
# Tu es maintenant dans la colonne droite

prefix + -        # split horizontal (coupe la pane courante en 2)
# Tu as maintenant 3 panes
```

Pour lancer nvim dans la pane de gauche :

```
prefix + h        # va à la pane de gauche
nvim .            # lance nvim
```

Pour lancer les tests dans la pane en haut à droite :

```
prefix + l        # va à droite
prefix + k        # va en haut
pytest            # lance les tests
```

### Navigation entre panes

Mes keybindings (config perso) utilisent le style vim :

| Raccourci | Action |
|---|---|
| `prefix + h/j/k/l` | Aller à la pane à gauche/bas/haut/droite |
| `prefix + z` | **Zoom** (full-screen de la pane courante, re-prefix+z pour dé-zoomer) |
| `prefix + x` | Tuer la pane courante (demande confirmation) |
| `prefix + H/J/K/L` | **Redimensionner** la pane (répétable) |
| `prefix + Space` | Cycler entre layouts prédéfinis |

### Bonus : navigation vim ↔ tmux fluide

Via le plugin `vim-tmux-navigator` installé dans ta config, les raccourcis `Ctrl-h/j/k/l` (**sans prefix**) fonctionnent **à travers nvim et tmux**. Donc dans nvim ou dans une pane shell, `Ctrl-l` te fait aller à droite quelle que soit ta pane actuelle. C'est magique.

### Windows (onglets)

```
prefix + c        # créer une nouvelle window
prefix + n        # window suivante
prefix + p        # window précédente
prefix + 1/2/3... # aller à la window N
prefix + ,        # renommer la window courante
prefix + w        # liste interactive des windows
prefix + &        # tuer la window courante
```

Raccourci sans prefix (perso) : **`Alt-1`** à **`Alt-5`** pour sauter directement à la window 1-5.

### Sessions

```
prefix + s        # liste interactive des sessions (super utile)
prefix + $        # renommer la session courante
prefix + d        # DÉTACHER (sortir de tmux sans tuer la session)
prefix + (        # session précédente
prefix + )        # session suivante
```

La touche **`d`** (détach) est **la** raison d'utiliser tmux : tu sors de la session, ton terminal se libère, et toutes tes commandes continuent de tourner. Tu fermes l'ordi ? Tu reviens le lendemain avec `tmux attach -t api` et tout est là.

### Copier du texte

Le **mode copie** est entré avec `prefix + [`. Dedans :

| Touche | Action |
|---|---|
| `h/j/k/l` | Bouger le curseur |
| `Space` | Commencer une sélection (après avoir appuyé sur `v` comme dans vim) |
| `v` | Sélection visuelle (mode tmux vi-mode, activé chez toi) |
| `V` | Sélection de lignes entières |
| `y` | **Yank** (copie) — va dans le système de presse-papier |
| `q` ou `Esc` | Quitter le mode copie |
| `/` | Recherche |
| `?` | Recherche en arrière |
| `n` / `N` | Résultat suivant / précédent |

Sur macOS, le `y` du mode copie met dans le vrai presse-papier système, donc tu peux coller avec `Cmd+V` ailleurs.

### tmux-resurrect : survivre au reboot

Tu as le plugin `tmux-resurrect` + `tmux-continuum` installés. Continuum sauvegarde automatiquement toutes les 15 min. Après un reboot :

```bash
❯ tmux                   # nouvelle session
# prefix + Ctrl-r        # RESTAURE la dernière session sauvegardée
```

Tes windows, panes, layouts, **et dossiers courants** sont restaurés. Les processus qui tournaient ne le sont pas (tmux ne peut pas ressusciter nvim avec son état interne), mais 90% du contexte est là.

### Workflow type avec tmux

Matin :

```bash
❯ tm api              # petite fonction : tmux new/attach -s api
# dans tmux :
# prefix + | -> split vertical
# nvim dans la gauche, tests à droite
# prefix + c -> nouvelle window pour lancer le serveur
# prefix + c -> nouvelle window pour les git commands
```

Tu bosses. À 18h :

```
prefix + d            # détache
```

Lendemain :

```bash
❯ tmux attach -t api  # tout est comme tu l'as laissé
```

Tu veux ajouter la fonction `tm` dans ton `~/.zshrc.local` ? Voilà :

```bash
tm() {
  local name="${1:-$(basename "$PWD")}"
  tmux new-session -A -s "$name"
}
```

`tm` sans argument → session nommée comme le dossier courant. `tm foo` → session "foo".

### Installer/updater les plugins tmux

TPM (plugin manager) est déjà installé. Si tu modifies la liste de plugins dans `~/.tmux.conf` :

```
prefix + I     # Install (touche majuscule i)
prefix + U     # Update
prefix + alt+u # Uninstall les plugins supprimés du config
```

---

## <a name="nvim"></a>5. Neovim + LazyVim — l'éditeur keyboard-first

LazyVim est une **distribution** Neovim : c'est une config pré-faite avec des plugins soigneusement sélectionnés. Tu as 150+ plugins activés sans avoir rien à configurer.

### Comprendre les modes de vim

Avant tout, un vim-crash-course en 30 secondes pour ceux qui arrivent de VS Code :

- **`Esc`** : mode **Normal** (navigation, commandes). C'est ici que tu passes le + de temps.
- **`i`** : mode **Insert** (comme un éditeur normal, tu tapes du texte)
- **`v`** : mode **Visual** (sélection)
- **`V`** : mode Visual-Line (sélection ligne par ligne)
- **`Ctrl-v`** : mode Visual-Block (sélection rectangulaire)
- **`:`** : mode **Command** (exécuter des commandes : `:w` save, `:q` quit)

En mode Normal, les lettres sont des commandes, pas du texte. `dd` → supprime la ligne. `yy` → copie la ligne. `p` → colle.

### Leader key : `Space`

Dans LazyVim, toutes les commandes custom commencent par **`Space`** (en mode Normal). C'est la "leader key".

### Les 5 raccourcis à mémoriser en premier

| Raccourci | Action | Équivalent VS Code |
|---|---|---|
| `<Space><Space>` | Fuzzy find fichiers du projet | `Cmd+P` |
| `<Space>/` | Live grep dans le projet | `Cmd+Shift+F` |
| `<Space>,` | Liste des buffers ouverts | `Cmd+Tab` |
| `<Space>e` | Toggle le file explorer (neo-tree) | `Cmd+B` |
| `<Space>?` | Afficher les raccourcis disponibles | Command Palette partiel |

Si tu te souviens de ces 5-là, tu peux déjà te débrouiller.

### La touche qui sauve : `<Space>`

Quand tu appuies sur **Space**, LazyVim attend 300ms, puis affiche un **menu** (via `which-key`) avec TOUTES les actions disponibles :

```
  f → +file                  (fichiers)
  g → +git
  c → +code                  (LSP, refactor, format)
  s → +search
  x → +diagnostics/quickfix
  ...
```

Tu tapes la lettre, ça descend dans le sous-menu. Plus besoin de mémoriser : tu **découvres** les raccourcis en naviguant.

Pareil pour **`g`** tout seul (commandes sous le préfixe `g`, comme `gd` goto-definition).

### Les mouvements de base (mode Normal)

| Touche | Action |
|---|---|
| `h j k l` | Gauche, bas, haut, droite (oui, vraiment) |
| `w` / `b` | Mot suivant / précédent |
| `W` / `B` | "Mot" au sens espaces (plus grand) |
| `0` / `$` | Début / fin de ligne |
| `gg` / `G` | Début / fin du fichier |
| `Ctrl-d` / `Ctrl-u` | Demi-page bas / haut |
| `{` / `}` | Paragraphe précédent / suivant |
| `%` | Sauter à la parenthèse/bracket/brace correspondante |
| `*` | Cherche le mot sous le curseur en avant |
| `f{char}` | Va au prochain `char` sur la ligne (ex: `f(` → sur la prochaine parenthèse) |
| `/foo` | Recherche "foo". `n` / `N` pour suivant/précédent |

### Les verbes (mode Normal)

| Touche | Action |
|---|---|
| `d` | Delete (cut) |
| `y` | Yank (copy) |
| `c` | Change (delete + insert) |
| `p` / `P` | Paste après / avant |
| `u` | Undo |
| `Ctrl-r` | Redo |
| `.` | Répète la dernière action |

Vim combine **verbe + mouvement**. Donc :

- `dw` = delete word (supprime jusqu'à la fin du mot)
- `d$` = delete jusqu'à la fin de la ligne
- `dd` = delete toute la ligne
- `yy` = yank toute la ligne
- `y3j` = yank les 3 prochaines lignes
- `ci"` = change inside `"..."` (change le contenu entre guillemets, très utilisé !)
- `da(` = delete around `(...)` (supprime avec les parenthèses)

### Édition sérieuse

| Raccourci | Action |
|---|---|
| `i` | Insert avant le curseur |
| `a` | Insert après le curseur (append) |
| `I` | Insert début de ligne |
| `A` | Insert fin de ligne |
| `o` | Nouvelle ligne en dessous + insert |
| `O` | Nouvelle ligne au-dessus + insert |
| `x` | Delete le char sous le curseur |
| `r{c}` | Replace 1 char par `c` |
| `>>` / `<<` | Indent / outdent |
| `~` | Swap la casse |

### LazyVim : les raccourcis custom

Les plus utiles (préfixe Space) :

| Raccourci | Action |
|---|---|
| `<Space>ff` | Find files (= `<Space><Space>`) |
| `<Space>fr` | Recent files |
| `<Space>fg` | Files tracked by git |
| `<Space>fb` | Find buffer |
| `<Space>/` | Live grep |
| `<Space>sg` | Search grep |
| `<Space>sh` | Search help (les docs vim) |
| `<Space>sk` | Search **keymaps** (parfait pour chercher un raccourci) |
| `<Space>e` | File explorer |
| `<Space>E` | File explorer, ancré au cwd |
| `<Space>gg` | lazygit |
| `<Space>w` puis `s/v/q` | Window split horizontal / vertical / close |
| `<Space>bd` | Close buffer |
| `<Shift-h>` / `<Shift-l>` | Buffer précédent / suivant |
| `<Space>?` | Help LazyVim |

### LSP (completions, go to definition, renommage)

Sur ton Mac, LazyVim a installé automatiquement les LSP pour Python, Go, Rust au premier lancement via Mason. Ils tournent en arrière-plan.

| Raccourci | Action |
|---|---|
| `K` | Hover documentation (appuie sur un mot, `K`, doc flottante) |
| `gd` | Go to Definition |
| `gr` | Go to References |
| `gi` | Go to Implementation |
| `gt` | Go to Type definition |
| `<Space>ca` | Code action (quick fix) |
| `<Space>cr` | Rename symbol (partout dans le projet) |
| `<Space>cf` | Format file |
| `<Space>cd` | Show diagnostic |
| `[d` / `]d` | Diagnostic précédent / suivant |

### Treesitter (coloration + selection intelligente)

Treesitter parse ton code en vrai AST. Résultat : les couleurs sont parfaites, mais surtout :

- **`v`** puis **`Ctrl+Space`** : étend la sélection au nœud suivant de l'AST. Super pratique pour sélectionner une expression, puis la fonction entière, etc.
- **`]f`** / **`[f`** : sauter à la fonction suivante/précédente

### Fermer / sauvegarder

```
:w                 # save
:wa                # save all
:q                 # quit
:wq                # save + quit
:q!                # force quit sans save
ZZ                 # save + quit (sans :)
ZQ                 # quit sans save
Ctrl-s             # save (configuré en plus dans ta config)
```

### Multi-fichiers : buffers

Dans nvim, chaque fichier ouvert est un **buffer**. Tu n'es pas forcé d'avoir 1 split par fichier.

```
<Space>,          # liste des buffers, fuzzy-navigable
<Shift-h>         # buffer précédent
<Shift-l>         # buffer suivant
<Space>bd         # delete current buffer (= fermer l'onglet)
<Space>bD         # delete + force (même si pas sauvegardé)
```

### Splits (fenêtres)

```
<Space>w puis:
  s       # split horizontal
  v       # split vertical
  q       # close this window
  w       # go to next window
  h/j/k/l # go to window in direction

<Ctrl-h/j/k/l>    # navigation split (grâce à vim-tmux-navigator)
```

### Terminal intégré

Pour lancer une commande sans quitter nvim :

```
<Space>ft         # terminal flottant (le plus joli)
<Space>fT         # terminal dans un split
```

Dans le terminal : **`Esc`** fait sortir du mode terminal (revient en Normal). **`i`** pour y retourner. **`<Space>bd`** pour le fermer.

### Un plugin très pratique : which-key + autocmd

Quand tu appuies sur une touche qui lance une séquence (comme `<Space>`), **which-key** t'affiche le menu. Tu n'as pas à tout mémoriser.

Pour **tout voir** à un moment : tu peux taper `<Space>sk` et fuzzy-chercher n'importe quel raccourci.

### LazyVim : commandes à connaître

```
:Lazy             # gestionnaire de plugins (liste, update, profile)
:LazyHealth       # diagnostic du setup
:Mason            # gestionnaire des LSPs/linters/formatters
:checkhealth      # vérif nvim lui-même
```

`:Lazy sync` force le refresh de tous les plugins. `:Lazy update` met à jour.

### Premier exercice concret

Ouvre un fichier Python :

```bash
❯ nvim quickstart.py
```

Dans nvim :

1. Tape `i` puis écris :
   ```python
   def hello(name):
       print(f"Hello, {name}")

   hello("World")
   ```

2. `Esc` pour sortir du mode insert.

3. Place le curseur sur `hello` dans la définition. `K` → tu vois la hover doc (vide au début, normal).

4. `gd` sur l'appel `hello("World")` en bas → ça te ramène à la définition. `<Ctrl-o>` → retour en arrière.

5. `<Space>cr` sur `hello` → rename. Tape `greet`, `Entrée`. Les 2 occurrences sont renommées.

6. `<Space>cf` → format le fichier (via ruff).

7. `<Space>ca` → code actions (sûrement rien pour ce mini fichier, mais c'est là qu'on voit "extract function", "add import", etc.).

8. `:w` pour sauver. `:q` pour quitter.

Tu viens de faire **5 actions LSP** que dans VS Code t'aurais faites à la souris. À la longue, c'est ça qui fait la différence.

---

## 🎯 Workflow type avec tout ce stack

```bash
# Lundi matin, j'ouvre mon terminal (tmux relance auto ma session "api")
❯ tm api

# 3 panes :
# - gauche : nvim
# - haut droite : lazygit
# - bas droite : shell pour tests/serveur

# Dans nvim :
<Space><Space>    # cherche un fichier
<Space>/          # cherche "TODO" dans le code
gd                # saute à une définition
<Space>cr         # renomme un symbol partout

# Dans lazygit :
a                 # stage tout
c                 # commit
# Je tape le message, Entrée
P                 # push

# Bascule entre panes avec Ctrl-h/j/k/l, sans jamais quitter tmux
```

**Prochaine partie** : les langages (Python/uv, Go, Rust) et Docker.
