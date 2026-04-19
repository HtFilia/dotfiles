# 🎓 Masterclass — Partie 4/4 : chezmoi, VS Code, workflows & cheat-sheet

> Maintenir ton setup au quotidien, les finitions VS Code, les combos avancés, et un cheat-sheet imprimable.

## Table des matières

1. [chezmoi — maintenir tes dotfiles](#chezmoi)
2. [VS Code — tirer parti de la config](#vscode)
3. [Ghostty — si tu veux migrer depuis iTerm2](#ghostty)
4. [Workflows avancés (combos)](#workflows)
5. [Astuces et tricks](#tricks)
6. [Cheat-sheet ultime](#cheatsheet)
7. [Ordre d'apprentissage suggéré](#ordre)

---

## <a name="chezmoi"></a>1. chezmoi — maintenir tes dotfiles

Tu as **3 répertoires** à garder en tête :

```
~/Documents/apps/dotfiles/       → TON REPO GIT (là où tu clones depuis GitHub)
~/.local/share/chezmoi/          → SOURCE (ce que chezmoi utilise pour appliquer)
~/                               → DESTINATION (tes vrais fichiers de config)
```

### Quel est le flux ?

```
Repo Git ──────push/pull──────> GitHub
   ↑                              │
   │                              │ (clone)
   │                              ▼
   │                        chezmoi source
   │                        (~/.local/share/chezmoi)
   │                              │
   │                              │ (chezmoi apply)
   │                              ▼
   └────commit depuis ici ──── ~/.zshrc, ~/.gitconfig, ...
```

Dans **ton cas spécifique** (vu tes messages), tu as cloné dans `~/Documents/apps/dotfiles`. Chezmoi, lui, a aussi sa source dans `~/.local/share/chezmoi`. Les deux existent en parallèle et ne sont pas forcément synchronisés.

### La commande qui résout tout : `chezmoi cd`

```bash
❯ chezmoi cd
# → te téléporte dans le répertoire source de chezmoi
#   (quelle que soit sa localisation sur la machine)
❯ pwd
/Users/toi/.local/share/chezmoi
# Tape `exit` pour revenir là où tu étais
```

Depuis `chezmoi cd`, tu fais tes `git add / commit / push` comme d'hab.

### Simplifier ton setup

Je te conseille **de ne garder qu'UN seul clone** sur chaque machine : celui que chezmoi utilise (`~/.local/share/chezmoi`). Pas besoin du clone dans `~/Documents/apps/dotfiles`.

Si tu veux absolument garder ton clone dans `~/Documents/apps/dotfiles` pour y accéder depuis ton file explorer, tu peux dire à chezmoi d'utiliser celui-là :

```bash
❯ chezmoi init --source=~/Documents/apps/dotfiles
```

Maintenant chezmoi utilisera directement ton clone, plus de duplication.

### Les 6 commandes que tu utiliseras

#### 1. Voir ce qui est géré

```bash
❯ chezmoi managed           # liste les fichiers gérés par chezmoi
❯ chezmoi managed -p absolute   # avec chemins absolus
```

#### 2. Voir ce qui diffère

```bash
❯ chezmoi diff              # diff entre source et destination
# Affiche via delta (grâce à ta config), donc c'est joli
```

C'est la commande à taper **avant** `chezmoi apply` pour savoir ce qui va changer.

#### 3. Appliquer

```bash
❯ chezmoi apply             # applique tout
❯ chezmoi apply -v          # verbose (dit ce qu'il fait)
❯ chezmoi apply ~/.zshrc    # un seul fichier
```

#### 4. Éditer

```bash
❯ chezmoi edit ~/.zshrc     # ouvre dans $EDITOR la VERSION SOURCE
# quand tu sauves, chezmoi ne "applique" pas automatiquement !

❯ chezmoi edit --apply ~/.zshrc   # édite + applique en sortant
❯ chezmoi edit --watch ~/.zshrc   # applique à CHAQUE save (pendant l'édition)
```

Personnellement je préfère `--watch` : tu modifies, tu sauves, tu vois l'effet dans un autre terminal. Si ça casse, tu annules et re-sauves.

#### 5. Ajouter un nouveau fichier

Tu as créé un nouveau fichier de config sur cette machine, tu veux le commit :

```bash
❯ chezmoi add ~/.config/mpv/mpv.conf
# → copie dans ~/.local/share/chezmoi/home/dot_config/mpv/mpv.conf
# Puis :
❯ chezmoi cd
❯ git add . && git commit -m "feat: add mpv config"
❯ git push
```

#### 6. Pull sur une autre machine

```bash
❯ chezmoi update
# équivalent à : git pull dans la source + chezmoi apply
```

### Résoudre un conflit

Tu as modifié un fichier directement sur une machine (sans passer par chezmoi), et du coup `chezmoi diff` te dit "le fichier sur disque est différent de la source".

```bash
❯ chezmoi diff               # voir la différence
```

Deux options :

**Option A** : "Je veux garder les modifs locales dans le repo"

```bash
❯ chezmoi re-add ~/.zshrc   # met à jour la source avec la version locale
❯ chezmoi cd && git commit -am "update from machine X"
```

**Option B** : "Je veux écraser mes modifs locales avec le repo"

```bash
❯ chezmoi apply ~/.zshrc    # écrase le fichier local
# ou, plus brutal :
❯ chezmoi apply --force
```

### Les templates : comprendre le mécanisme

Les fichiers qui finissent en `.tmpl` dans le repo sont passés à travers un moteur de templates Go. Les variables disponibles :

```
{{ .chezmoi.os }}               # "darwin", "linux"
{{ .chezmoi.arch }}             # "amd64", "arm64"
{{ .chezmoi.hostname }}         # hostname système
{{ .chezmoi.username }}         # $USER
{{ .chezmoi.kernel.osrelease }} # utile pour détecter WSL

{{ .name }}                     # ce que tu as répondu à chezmoi init
{{ .email }}
{{ .machineType }}              # "personal" | "work"
{{ .hostname }}
```

Exemple dans ton `.zshrc.tmpl` :

```go-template
{{- if eq .chezmoi.os "darwin" }}
alias flushdns='sudo dscacheutil -flushcache'
{{- else }}
alias pbcopy='xclip -sel clip'
{{- end }}
```

### Le fichier `.chezmoiignore`

`~/.local/share/chezmoi/.chezmoiignore` (à la racine de la source) liste ce que chezmoi **ne doit pas** appliquer. Syntaxe type `.gitignore`.

Utile si tu veux garder un fichier dans le repo mais pas l'appliquer (ex : le README). Dans notre repo, c'est déjà le cas.

### Les fichiers .local : per-machine

Mon `.zshrc` fait `source ~/.zshrc.local` à la fin s'il existe. Ce fichier n'est **PAS** géré par chezmoi (il est dans `.gitignore`) → tu peux y mettre des variables spécifiques à une machine, sans polluer le repo :

```bash
# ~/.zshrc.local
export ANTHROPIC_API_KEY="..."
export COMPANY_INTERNAL_URL="https://intranet.foo"
alias vpn="sudo openconnect corp.foo"
```

Pareil pour `~/.gitconfig.local` :

```toml
[user]
    email = "toi@ta-boite.com"
    signingkey = "ABCD1234..."
```

### Le workflow de modification quotidien

```bash
# Je veux changer mon prompt
❯ chezmoi edit ~/.config/starship.toml
# Modifie, save, quit

❯ chezmoi diff                   # voir l'effet
❯ chezmoi apply

# J'aime le résultat, je commit
❯ chezmoi cd
❯ g s                            # git status
❯ gaa && gcm "feat: tweak starship prompt"
❯ gp
❯ exit                           # sort du `chezmoi cd`

# Sur l'autre machine :
❯ chezmoi update                 # pull + apply d'un coup
```

---

## <a name="vscode"></a>2. VS Code — tirer parti de la config

VS Code est installé avec la config par chezmoi. Il ne te reste qu'à installer les extensions.

### Installer toutes les extensions d'un coup

Dans ton repo, il y a un fichier `extensions.txt`. Exécute :

```bash
❯ cd ~/Documents/apps/dotfiles   # ou $(chezmoi source-path)
❯ cat extensions.txt | xargs -L1 code --install-extension
```

Ça installe en quelques minutes Tokyo Night, Material Icon Theme, Error Lens, GitLens, les LSP Python / Go / Rust, Prettier, Docker, WSL Remote, Claude Code, etc.

### Ce qui est déjà configuré

Grâce à `settings.json` (dans le repo) :

- **Thème** Tokyo Night, font FiraCode Nerd Font
- **Format on save** + **organize imports on save** (pour tous les fichiers)
- **Python** : Ruff comme formatter, Pylance pour le typage
- **Go** : gopls LSP, goimports au format, golangci-lint
- **Rust** : rust-analyzer avec inlay hints et clippy
- **Prettier** pour JSON/YAML/Markdown
- **ErrorLens** : affiche les erreurs/warnings inline (plus besoin de hover)
- **GitLens** sans les code lens envahissantes
- **Telemetry** complètement désactivée

### Les raccourcis que tu as mis

Dans `keybindings.json` :

| Raccourci | Action |
|---|---|
| `Cmd-O` (Mac) / `Ctrl-O` | Quick Open file (fuzzy) |
| `Cmd-B` | Toggle sidebar |
| `Alt-↑` / `Alt-↓` | Déplacer la ligne courante |
| `Shift-Alt-↓` | Dupliquer la ligne |
| `Shift-Alt-F` | Format document |

### Terminal intégré

VS Code lance **Zsh** par défaut (configuré). Le terminal intégré utilise aussi FiraCode Nerd Font. Tu peux donc travailler entièrement dans VS Code si tu préfères, avec tmux dedans.

### Remote-WSL (sur Windows)

Sur ton Windows avec WSL, installe VS Code **sur Windows**, pas dans WSL. L'extension "Remote - WSL" fera la magie : tu ouvres un dossier WSL, VS Code se connecte au serveur linux, tu édites côté Windows avec toute la perf côté Linux.

### VS Code vs Neovim : quand utiliser quoi ?

C'est une fausse opposition. Tu peux avoir les deux :

- **Neovim** pour les éditions rapides, les refactorings à la volée, les sessions dans tmux, le travail sur serveur distant
- **VS Code** pour les sessions de débug (les UI de debug sont meilleures), les extensions spécifiques (Jupyter notebooks, extensions métier)

Tu peux même utiliser **l'extension Vim pour VS Code** pour avoir les bindings vim partout.

---

## <a name="ghostty"></a>3. Ghostty — si tu veux migrer depuis iTerm2

Tu utilises iTerm2 actuellement. Rien t'oblige à migrer. Mais voici les arguments pour passer à Ghostty (installé par le bootstrap) :

- **Rapidité** : accélération GPU native (Metal sur macOS). iTerm2 est rapide aussi, mais Ghostty est le + rapide.
- **Config as code** : ta config est dans `~/.config/ghostty/config` (versionée dans le repo). iTerm2 garde ses préférences dans un plist binaire, dur à synchroniser entre machines.
- **Multi-plateforme** : même config sur macOS et Linux (pas iTerm2 qui est Mac-only).

### Pour essayer Ghostty

```bash
❯ open -a Ghostty    # ou via Spotlight
```

Ta config est déjà appliquée (ghostty lit automatiquement `~/.config/ghostty/config`). Tu auras Tokyo Night et FiraCode.

### Si tu restes sur iTerm2

Fais juste 2 choses pour avoir une expérience cohérente :

1. Réglages → Profiles → Text → Change Font → **FiraCode Nerd Font**, taille 14
2. Réglages → Profiles → Colors → Color Presets → **Import** → télécharge un `.itermcolors` Tokyo Night (y'en a sur GitHub, cherche "tokyo night itermcolors")

---

## <a name="workflows"></a>4. Workflows avancés (combos)

Les combos d'outils qui font gagner le plus de temps.

### Combo 1 : explorer un code inconnu en 30 secondes

Tu clones un repo d'un collègue. Comment le comprendre vite ?

```bash
❯ git clone foo && cd foo

# 1. Vue d'ensemble du projet
❯ eza --tree --level=2 --git-ignore

# 2. Les fichiers principaux (souvent les plus gros)
❯ tokei .                          # si installé : lignes par langage
# ou :
❯ fd -e py -e js -e go | xargs wc -l | sort -n | tail -20

# 3. Chercher les entry points
❯ rg "def main|if __name__|fn main|func main" --no-heading

# 4. Lire le README et docs
❯ bat README.md
❯ fd -e md | head

# 5. Quelles dépendances ?
❯ bat pyproject.toml Cargo.toml go.mod package.json 2>/dev/null

# 6. Demander à Claude !
❯ cc
> explain the structure of this codebase
```

### Combo 2 : refactor global en sécurité

Tu veux renommer une fonction dans 50 fichiers.

**Option A — LSP (le plus safe)** : ouvre le fichier, curseur sur le nom, `<Space>cr` dans nvim. Le LSP trouve TOUTES les occurrences, te montre un preview, tu valides.

**Option B — rg + sed (pour les cas non gérés par le LSP)** :

```bash
# 1. Voir toutes les occurrences
❯ rg "old_name" --no-heading

# 2. Voir quels fichiers
❯ rg -l "old_name"

# 3. Faire le remplacement (avec sed)
❯ rg -l "old_name" | xargs sed -i.bak "s/old_name/new_name/g"
# Note : sur macOS, c'est `sed -i ''` avec un espace vide (pas `sed -i`)
# Les .bak sont les backups automatiques
```

**Option C — demander à Claude Code** :

```
> rename `old_api_call` to `new_api_call` everywhere, but only in Python files
```

### Combo 3 : suivi de bug en temps réel

Tu lances ton app, un bug apparaît dans les logs. Tu veux corriger sans redémarrer.

```bash
# Pane 1 (tmux gauche)
❯ nvim .

# Pane 2 (tmux haut droite)
❯ uv run uvicorn main:app --reload
# → redémarre automatiquement à chaque save

# Pane 3 (tmux bas droite)
❯ dc logs -f db          # ou tout autre log à suivre
```

Tu édites dans nvim, le serveur redémarre auto, tu vois les logs live, tu corriges, tu testes — tout sans quitter ta fenêtre.

### Combo 4 : sauvegarde d'état de travail

Tu vas partir manger, mais tu veux reprendre exactement où tu en étais.

```bash
# Dans tmux : prefix + d
# → tu détaches la session, tes processus continuent de tourner

# En revenant :
❯ tmux attach -t api
# tout est là
```

Si tu reboot l'ordi : `tmux-resurrect` via `prefix + Ctrl-r` restaure ta dernière session sauvegardée (layout + cwd par pane).

### Combo 5 : debug réseau

Ton service appelle une API et ça marche pas.

```bash
# Tester l'endpoint directement
❯ curl -v https://api.example.com/health | bat -l json

# Voir les DNS
❯ dig api.example.com

# Voir ce que ton app envoie (si linux)
❯ sudo tcpdump -i any port 443 -A

# Simuler l'API en local (container rapide)
❯ docker run --rm -p 8080:80 kennethreitz/httpbin
❯ curl localhost:8080/get
```

### Combo 6 : archive rapide d'un dossier

```bash
# Zip un dossier en excluant node_modules, .git, etc.
❯ fd . -H -I -t f -E node_modules -E .git -E target -E __pycache__ | \
    tar czf archive.tar.gz -T -
```

(`-T -` dit à tar de lire les noms depuis stdin.)

---

## <a name="tricks"></a>5. Astuces et tricks

### Ctrl-Z / fg : "arrière-plan rapide"

Tu lances une commande longue, tu veux faire autre chose sans ouvrir un nouveau terminal :

```bash
❯ ./slow_script.sh
# Ctrl-Z         → pause le script
[1]+  Stopped

❯ do_other_stuff

❯ fg             # reprend le script au premier plan
# ou
❯ bg             # le relance en arrière-plan
❯ jobs           # voir ce qui est en pause
```

### !! et !$ : recycler la dernière commande

```bash
❯ cat /etc/hosts
# (permission denied)
❯ sudo !!
# → relance `sudo cat /etc/hosts`

❯ vim ~/.config/nvim/init.lua
❯ cat !$
# → `cat ~/.config/nvim/init.lua` (même dernier argument)

❯ !grep
# → répète la dernière commande commençant par "grep"
```

### Ctrl-X Ctrl-E : éditer une longue commande dans vim

Tu as tapé une commande de 10 lignes avec des pipes, tu veux la modifier au calme :

```bash
❯ long | command | with | many | pipes    [Ctrl-X Ctrl-E]
# → ça ouvre nvim avec ta commande dedans
# tu modifies, :wq, et ça l'exécute
```

### Les crochets "inside/around" de vim

Tu es dans nvim, curseur sur un mot au milieu d'une chaîne :

```python
name = "Alice"
#        ^ curseur
```

- `ci"` = change inside `"..."` → efface "Alice" et te met en insert
- `da"` = delete around `"..."` → efface `"Alice"` (guillemets inclus)
- `yi(` = yank inside `(...)` → copie ce qui est entre parens
- `ci]` = change inside `[...]`
- `cit` = change inside tag (pour HTML)

C'est le type de raccourci que tu dois voir 1 fois et qui change ta vie.

### fzf + kill

```bash
❯ ps aux | fzf | awk '{print $2}' | xargs kill
# Interactive process killer
# (c'est + ou - ce que fait la fonction `fkill` dans ton zshrc)
```

### Preview fzf très puissant

```bash
❯ export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
"
```

Déjà configuré dans ton `.zshrc`. Ctrl-T ouvre fzf, panneau de preview avec le contenu du fichier. Ctrl-/ cycle entre "à droite", "en bas", "caché".

### Comparer 2 dossiers

```bash
❯ diff -r dir1 dir2 | delta
```

### Stats sur un repo

```bash
❯ git shortlog -sn                           # contributeurs triés
❯ git log --oneline | wc -l                  # nombre de commits
❯ git log --format='%ad' --date=short | sort | uniq -c | tail -30
# → nombre de commits par jour, 30 derniers jours
```

### Renommer en masse avec zsh

```bash
❯ autoload -U zmv
❯ zmv '(*).txt' '$1.md'     # rename tous les .txt en .md
```

### Colorier n'importe quelle commande

```bash
# Pipe vers bat avec un "language" pour forcer la coloration
❯ echo '{"key": "value"}' | bat -l json
❯ echo 'SELECT * FROM users' | bat -l sql
```

### Un secret bien caché de tmux

Tu as 5 panes, tu veux déplacer la courante vers la 3e window ?

```
prefix + !         # break pane into new window
prefix + {         # swap pane with previous
prefix + }         # swap pane with next
```

Et :

```
prefix + Space     # cycle les layouts (tiled, even-horizontal, main-vertical...)
```

---

## <a name="cheatsheet"></a>6. Cheat-sheet ultime

### Shell & navigation

```
cd <name>         fuzzy cd via zoxide
cdi               cd interactive fzf
Ctrl-T            fuzzy files
Alt-C             fuzzy cd
Ctrl-R            atuin history search
fe / fcd          fuzzy edit / fuzzy cd (custom)
!!                dernière commande
!$                dernier argument
Ctrl-X Ctrl-E     édite commande dans $EDITOR
```

### Fichiers

```
ll / la / lt      listings (eza)
bat <file>        cat coloré
fd <pattern>      find moderne
rg <pattern>      grep moderne
mkcd <dir>        mkdir + cd
extract <file>    unarchive anything
```

### Git

```
g, gs, gl, gd     status / log / diff
ga, gaa, gcm      add / add all / commit -m
gp, gpl           push / pull
gco, gcb          checkout / checkout -b
lg                lazygit
```

### Lazygit

```
1..5              aller au panneau
a                 stage all
Space             stage file/line
c                 commit
P                 push
i                 rebase interactif
?                 aide contextuelle
q                 quitter
```

### tmux (prefix = Ctrl-a)

```
prefix + |        split vertical
prefix + -        split horizontal
prefix + c        new window
prefix + h/j/k/l  navigation pane
prefix + z        zoom
prefix + d        detach
prefix + s        list sessions
Ctrl-h/j/k/l      nav pane ET nvim (vim-tmux-navigator)
```

### Neovim (leader = Space)

```
<Space><Space>    find file
<Space>/          live grep
<Space>,          buffers
<Space>e          file explorer
<Space>gg         lazygit
<Space>?          help

gd                go to definition
gr                references
K                 hover doc
<Space>ca         code action
<Space>cr         rename symbol
<Space>cf         format

Shift-h / Shift-l buffer prev/next
Ctrl-s            save
```

### Vim-motions (Normal mode)

```
w / b             next/prev word
0 / $             start/end of line
gg / G            file start/end
Ctrl-d / Ctrl-u   half page down/up
f<char>           jump to next <char> on line
/<text>           search
*                 search word under cursor

dd / yy / p       delete/yank/paste line
ci"  ca" yi(  di(  ci]  cit    inside/around magic

u / Ctrl-r        undo/redo
.                 repeat last action
```

### Python (uv)

```
uv init                  new project
uv add <pkg>             add dependency
uv add --dev <pkg>
uv sync                  install from lock
uv run <cmd>             run in project env
uv python install 3.12
uv tool install <cli>    global CLI
uvx <cli>                run without installing
```

### Go

```
go mod init <name>
go get <pkg>
go run .
go test ./...
go build
go install <pkg>@latest
```

### Rust

```
cargo new <name>
cargo add <crate>
cargo run [--release]
cargo test
cargo clippy
cargo fmt
cargo install <crate>
```

### Docker

```
d, dc              docker / docker compose
dps, dpsa          ps (pretty)
dex <c> bash       exec bash in container
dlog <c>           follow logs
dc up -d           compose up detached
dc down [-v]       compose down
dc logs -f <svc>
```

### chezmoi

```
chezmoi cd               va au source
chezmoi apply            applique
chezmoi diff             montre ce qui changerait
chezmoi edit <file>      edit source
chezmoi add <file>       ajoute nouveau fichier
chezmoi update           pull + apply
chezmoi re-add <file>    mise à jour depuis dest
```

### Claude Code

```
cc                 start
ccr                resume last
/clear             reset context
/cost              voir coût
/help              aide
```

---

## <a name="ordre"></a>7. Ordre d'apprentissage suggéré

Tu ne vas pas tout retenir d'un coup. Je te recommande cet ordre, sur 3-4 semaines :

### Semaine 1 : les fondations du shell

- Autosuggestions (flèche droite pour accepter)
- `zoxide` : réapprendre `cd` à naviguer intelligemment
- `eza` (aliases `ll`, `la`, `lt`)
- `bat` à la place de cat
- `Ctrl-R` pour l'historique (atuin)
- `Ctrl-T` et `Alt-C` pour fzf
- Les alias git du shell : `gs`, `gl`, `gaa`, `gcm`, `gp`

Objectif : ne plus taper de chemins complets, ne plus écrire `git status`.

### Semaine 2 : tmux + lazygit

- tmux : prefix + |, -, c, d, s, Ctrl-h/j/k/l
- lazygit : 1-5, Space, a, c, P, i
- chezmoi edit / apply / commit / push

Objectif : ne plus jamais ouvrir plusieurs fenêtres de terminal, ne plus quitter le terminal pour gérer git.

### Semaine 3 : Neovim

- Les modes (Insert/Normal/Visual)
- Les motions de base (w, b, $, gg, G)
- d / y / c + motions (dw, cw, di", ci()
- `<Space><Space>` pour ouvrir, `<Space>/` pour chercher
- LSP : gd, K, `<Space>cr`, `<Space>ca`

Objectif : devenir 2× plus lent que dans VS Code (normal, tu apprends). Dans 2 mois tu seras 2× plus rapide.

### Semaine 4 : langages & Docker

- Workflow uv : init, add, run, sync
- Docker compose pour les services locaux
- direnv pour auto-charger les envs

### Au-delà

- Rebase interactif dans lazygit (touche i)
- Les text objects vim avancés (`vi{`, `va[`, `cit`)
- fzf avec preview personnalisées
- Claude Code pour refactor et code review

### Ressources pour approfondir

- **Neovim** : `:Tutor` dans nvim, puis <https://learnvimscriptthehardway.stevelosh.com/> (malgré le nom, c'est une super intro)
- **tmux** : <https://leanpub.com/the-tao-of-tmux/read> (gratuit)
- **Git interne** : <https://git-scm.com/book/en/v2> (surtout le chapitre 10, Git Internals)
- **Rust** : le livre officiel <https://doc.rust-lang.org/book/>
- **LazyVim** : `<Space>L` dans nvim → accès direct à la doc interactive

---

## 🎉 Tu as fini

Ce setup est conçu pour grandir avec toi. Les configs que tu versionnes aujourd'hui dans chezmoi seront tes outils dans 5 ans. Chaque fois que tu découvres un truc utile (un alias, une fonction, un plugin), commit-le, push, et il sera sur toutes tes machines.

**Prochaine étape qui change tout** : ouvre nvim, tape `:Tutor`, et fais le tutoriel intégré (30 minutes). C'est ce qui va te débloquer pour vraiment utiliser Neovim au quotidien.

Si tu as des questions en route, tu peux toujours relancer Claude Code dans ton projet et demander.

Bon code ! 🚀
