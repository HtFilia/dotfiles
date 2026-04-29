# 🎓 Masterclass — Partie 3/4 : Langages & Dev

> uv pour Python, Go, Rust (rustup + cargo), Docker, et fnm pour Node.

## Table des matières

1. [uv — le futur de Python](#uv)
2. [fnm — Node version manager](#fnm)
3. [Go — apt ou GitHub](#go)
4. [Rust — cargo + rustup](#rust)
5. [Docker / Podman — aliases et patterns](#docker)
6. [Claude Code — l'assistant dans ton terminal](#claude)

---

## <a name="uv"></a>1. uv — le futur de Python

**uv** (par Astral, les gens de ruff) remplace `pip`, `pipx`, `virtualenv`, `pyenv`, `poetry`, et `pip-tools` en un seul binaire écrit en Rust. Il est 10 à 100× plus rapide que pip.

### Installer Python avec uv

C'est le game-changer. Pas besoin de pyenv ou d'un Homebrew Python.

```bash
❯ uv python install 3.12          # installe Python 3.12
❯ uv python install 3.13          # ...et 3.13
❯ uv python list                  # voir les versions dispo + installées
❯ uv python pin 3.12              # épingle 3.12 pour ce projet (crée .python-version)
```

Les versions sont installées dans `~/.local/share/uv/python/`. Elles sont **portables** et pas liées au système.

### Créer un projet Python from scratch

```bash
❯ uv init mon_api
❯ cd mon_api
❯ ls
# pyproject.toml  README.md  .python-version  main.py
```

Il crée déjà un `pyproject.toml` avec la version Python épinglée.

### Ajouter des dépendances

```bash
❯ uv add requests                 # ajoute à pyproject.toml ET installe
❯ uv add --dev pytest ruff        # en dev dependency
❯ uv add 'django>=4,<5'           # avec spécificateur de version
❯ uv add -r requirements.txt      # depuis un requirements.txt existant
```

La différence avec pip : **uv maintient un lockfile** (`uv.lock`) qui fige les versions exactes, comme Cargo.lock ou package-lock.json. Ça garantit que tes collègues et la CI ont **exactement** les mêmes versions.

### Lancer du code

```bash
❯ uv run python main.py           # exécute dans l'env du projet
❯ uv run pytest                   # idem pour pytest
❯ uv run ruff check               # idem pour ruff
```

**Pas besoin d'activer le venv manuellement**. `uv run` le fait pour toi.

Si tu préfères l'activer malgré tout (par habitude) :

```bash
❯ source .venv/bin/activate       # ou mieux, via direnv (partie 1)
```

### Synchroniser un projet existant

Tu as cloné un projet qui utilise uv :

```bash
❯ git clone https://github.com/user/projet
❯ cd projet
❯ uv sync                         # lit pyproject.toml + uv.lock, installe tout
```

C'est ultra rapide (quelques secondes pour des centaines de paquets).

### Installer des outils CLI Python

Pour les outils globaux (ruff, black, pre-commit, httpie...), `uv tool` remplace `pipx` :

```bash
❯ uv tool install ruff            # installe ruff en global, isolé
❯ uv tool install black
❯ uv tool install httpie
❯ uv tool list                    # voir ce qui est installé
❯ uv tool upgrade --all           # update tout
❯ uv tool uninstall ruff
```

Ou lancer sans installer :

```bash
❯ uvx ruff check .                # équivalent de `pipx run ruff`
❯ uvx --python 3.11 ruff check .  # avec une version Python précise
```

### Exemples courants

```bash
# Créer un script rapide avec des dépendances inline (PEP 723)
❯ cat > script.py <<'EOF'
# /// script
# dependencies = ["requests"]
# ///
import requests
print(requests.get("https://api.github.com").status_code)
EOF
❯ uv run script.py
# uv lit le header, crée un venv éphémère avec requests, lance le script

# Publier un package (remplace twine)
❯ uv build
❯ uv publish

# Voir l'arbre des dépendances
❯ uv tree

# Mettre à jour une dépendance
❯ uv lock --upgrade-package requests

# Supprimer une dépendance
❯ uv remove requests
```

### Workflow type Python avec uv + direnv

```bash
❯ mkdir mon_projet && cd mon_projet
❯ uv init
❯ uv add fastapi uvicorn

# Activation auto via direnv
❯ echo "source .venv/bin/activate" > .envrc
❯ direnv allow

# uv a créé le venv auto au premier 'uv add'
# À chaque cd mon_projet, direnv active le venv

❯ uv add --dev pytest ruff mypy
❯ uv run pytest
❯ uv run ruff check .
```

---

## <a name="fnm"></a>2. fnm — Node version manager

**fnm** (Fast Node Manager) remplace nvm. Il est écrit en Rust, 40× plus rapide au shell startup.

Dans ton `.zshrc`, j'ai mis `eval "$(fnm env --use-on-cd ...)"`. Résultat : **si tu `cd` dans un projet avec un `.nvmrc` ou un `.node-version`, fnm switch automatiquement de version Node.**

### Installer une version Node

```bash
❯ fnm install 22                  # dernière 22.x
❯ fnm install --lts               # dernière LTS
❯ fnm install 20.11.0             # version exacte
❯ fnm list                        # voir les versions installées
❯ fnm list-remote | tail -20      # voir les 20 dernières dispo
```

### Utiliser une version

```bash
❯ fnm use 22                      # dans ce shell uniquement
❯ fnm default 22                  # définir la version par défaut
❯ fnm current                     # quelle version est active ?
```

### Auto-switch par projet

```bash
❯ cd mon_projet
❯ echo "22.5.0" > .nvmrc          # ou .node-version
❯ cd ..
❯ cd mon_projet                   # fnm switch auto à 22.5.0
```

### Commandes Node usuelles

Une fois Node actif, `npm`, `npx`, et les packages globaux sont isolés par version :

```bash
❯ node -v
❯ npm init -y
❯ npm install express
❯ npx create-next-app
```

---

## <a name="go"></a>3. Go — apt ou GitHub

Go sur Mac est installé via Homebrew, sur Debian via apt (parfois trop ancien → on build depuis GitHub en mode restricted).

### Les commandes Go essentielles

```bash
❯ go version                      # vérifier

# Créer un projet
❯ mkdir mon_api && cd mon_api
❯ go mod init github.com/toi/mon_api    # init le module (nom = chemin du repo)

# Ajouter des dépendances
❯ go get github.com/gin-gonic/gin       # récupère et ajoute à go.mod
❯ go get -u                             # update toutes les deps

# Lancer
❯ go run main.go                        # build temp + exécute
❯ go run .                              # run le package courant

# Builder un binaire
❯ go build                              # binaire dans le dossier courant
❯ go build -o api ./cmd/api             # binaire nommé "api"

# Tests
❯ go test ./...                         # tous les tests du projet
❯ go test -v ./pkg/auth                 # un package précis, verbose
❯ go test -race ./...                   # avec le race detector
❯ go test -cover ./...                  # avec coverage
❯ go test -bench=.                      # benchmarks

# Format, vet, lint
❯ gofmt -w .                            # format tous les .go (déjà fait par LazyVim à la sauvegarde)
❯ go vet ./...                          # analyse statique basique
❯ go mod tidy                           # nettoie go.mod des deps inutilisées
```

### Installer un outil Go en global

```bash
❯ go install github.com/user/tool@latest
# Le binaire arrive dans ~/go/bin, déjà dans ton PATH
```

Exemples utiles :

```bash
❯ go install golang.org/x/tools/gopls@latest      # LSP Go (déjà installé par LazyVim)
❯ go install github.com/air-verse/air@latest      # hot reload pour dev Go
```

### Workspaces multi-modules (Go 1.18+)

Si tu bosses sur plusieurs modules liés :

```bash
❯ go work init ./module1 ./module2
# Go va utiliser tes modifs locales plutôt que les versions publiées
```

---

## <a name="rust"></a>4. Rust — cargo + rustup

### rustup : le manager de toolchains

```bash
❯ rustup show                     # toolchain active + installées
❯ rustup update                   # update stable
❯ rustup install nightly          # ajouter nightly
❯ rustup default stable           # définir le défaut
❯ rustup override set nightly     # pour ce dossier seulement (créé rust-toolchain.toml)
```

### cargo : build tool + package manager

```bash
# Créer un projet
❯ cargo new mon_projet            # binaire
❯ cargo new --lib ma_lib          # library
❯ cd mon_projet

# Dépendances : éditer Cargo.toml OU :
❯ cargo add serde --features derive
❯ cargo add tokio --features full
❯ cargo remove unused_dep

# Builder
❯ cargo build                     # debug (rapide à compiler, lent à l'exécution)
❯ cargo build --release           # optimisé
❯ cargo run                       # build + run
❯ cargo run --release
❯ cargo run -- arg1 arg2          # args à ton programme après --

# Tests
❯ cargo test
❯ cargo test --release
❯ cargo test nom_du_test          # filtre par nom
❯ cargo test -- --nocapture       # voir les println! pendant les tests

# Lint
❯ cargo clippy                    # linter (super recommandé)
❯ cargo clippy --fix              # auto-fix ce qui peut l'être
❯ cargo fmt                       # format

# Nettoyer
❯ cargo clean                     # vire le dossier target/
❯ cargo update                    # met à jour Cargo.lock
```

### Installer des outils Rust en global

Comme pour Go :

```bash
❯ cargo install ripgrep           # installe rg (déjà fait)
❯ cargo install bottom            # alternative à htop
❯ cargo install tokei             # compteur de lignes par langage
❯ cargo install --list            # voir tout ce qui est installé
```

### Cargo watch : le hot-reload

```bash
❯ cargo install cargo-watch
❯ cargo watch -x run              # relance cargo run à chaque modif
❯ cargo watch -x test             # relance les tests à chaque modif
```

### Cargo features

Les dépendances Rust ont souvent des "features" optionnelles. Dans `Cargo.toml` :

```toml
[dependencies]
serde = { version = "1", features = ["derive"] }
tokio = { version = "1", features = ["full"] }
```

Pour tester ton projet avec/sans une feature :

```bash
❯ cargo build --features foo
❯ cargo build --no-default-features
❯ cargo build --all-features
```

---

## <a name="docker"></a>5. Docker / Podman — aliases et patterns

Ta config a déjà des aliases pratiques.

### Les aliases installés

| Alias | Commande |
|---|---|
| `d` | `docker` |
| `dc` | `docker compose` |
| `dps` | `docker ps` formaté joliment |
| `dpsa` | `docker ps -a` |
| `di` | `docker images` |
| `dex` | `docker exec -it` |
| `dlog` | `docker logs -f` |
| `dprune` | `docker system prune -af --volumes` (nettoyage brutal) |

### Les 20% à connaître par cœur

```bash
# Lancer un container
❯ docker run --rm -it ubuntu bash           # interactif, supprimé à la fin
❯ docker run -d --name api -p 8080:8080 myimage  # daemon, nommé, ports mappés
❯ docker run -v $PWD:/app node:20 npm test  # monte le dossier courant

# Voir ce qui tourne
❯ dps                                        # running
❯ dpsa                                       # tous, même stoppés

# Logs
❯ dlog api                                   # follow les logs du container "api"
❯ docker logs --tail 100 api

# Entrer dans un container
❯ dex api bash                               # shell dans "api"
❯ dex api python                             # juste lancer python dedans

# Stop / start / restart
❯ docker stop api
❯ docker start api
❯ docker restart api

# Supprimer
❯ docker rm api                              # container (doit être stoppé)
❯ docker rm -f api                           # force stop + rm
❯ docker rmi myimage                         # image

# Build
❯ docker build -t myimage .
❯ docker build -t myimage:v2 --target prod . # multi-stage, cible prod

# Tags et push
❯ docker tag myimage:latest registry.example.com/user/myimage:v1
❯ docker push registry.example.com/user/myimage:v1
```

### docker compose

C'est ce que tu utiliseras 90% du temps. Fichier `compose.yml` (ou `docker-compose.yml`) :

```yaml
services:
  api:
    build: .
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgres://db:5432/app
    depends_on:
      - db
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

Commandes :

```bash
❯ dc up                           # lance tout (fg)
❯ dc up -d                        # detached (bg)
❯ dc up --build                   # rebuild les images avant
❯ dc down                         # stop + rm les containers (garde les volumes)
❯ dc down -v                      # + supprime les volumes (attention !)

❯ dc ps                           # état des services
❯ dc logs                         # tous les logs
❯ dc logs -f api                  # suivi des logs d'un service
❯ dc exec api bash                # shell dans le service api
❯ dc restart api
❯ dc pull                         # update les images depuis le registry
```

### Nettoyage

Docker bouffe vite de la place. Commandes de ménage :

```bash
❯ docker system df                # voir ce qui prend de la place
❯ docker container prune          # supprime les stoppés
❯ docker image prune              # supprime les dangling
❯ docker image prune -a           # supprime TOUS ceux non utilisés
❯ docker volume prune             # supprime les volumes orphelins
❯ dprune                          # alias : tout nettoyer en 1 commande (attention)
```

### Astuces

**Voir la taille des images** :

```bash
❯ docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | sort -k2 -h
```

**Run + remove immédiat** (pour tester une commande dans un env propre) :

```bash
❯ docker run --rm -it python:3.12 python
# Un REPL Python 3.12, container supprimé à la sortie
```

**Copier depuis/vers un container** :

```bash
❯ docker cp api:/app/logs.txt ./
❯ docker cp ./config.yml api:/app/
```

**Inspecter** :

```bash
❯ docker inspect api | less       # tout savoir
❯ docker inspect -f '{{.State.Status}}' api   # juste le status
❯ docker port api                 # les ports mappés
```

### Docker Desktop vs alternatives

Sur ton Mac, tu utilises probablement Docker Desktop (gratuit pour usage perso, payant pour grosses boîtes). Si tu veux l'éviter :

- **Colima** : VM + Docker CLI, open source, léger. `brew install colima && colima start`
- **Podman Desktop** : alternative Red Hat

Ta config gère les deux (l'alias `d` pointe vers `docker` si dispo, sinon `podman`).

---

## <a name="claude"></a>6. Claude Code — l'assistant dans ton terminal

Claude Code est un CLI où tu parles à Claude (version Sonnet/Opus) depuis ton terminal, avec accès à ton code.

### Lancer

```bash
❯ cc                              # alias pour `claude`
# ou
❯ claude
```

Premier lancement : il te demande de login avec ton compte Anthropic.

### Commandes dans la session

Une fois dans Claude Code, tu tapes des messages en langage naturel. Claude peut :

- Lire les fichiers de ton projet
- Proposer des modifications et demander confirmation
- Exécuter des commandes shell (avec ta permission)
- Créer / supprimer des fichiers
- Faire des recherches dans le code

Exemples :

```
> refactor auth.py to use async/await
> explain this codebase
> add tests for the login function
> what does this error mean?
> commit my changes with a good message
```

### Commandes slash

Dans la session Claude Code :

| Commande | Action |
|---|---|
| `/help` | Aide |
| `/clear` | Efface le contexte (nouvelle conversation) |
| `/exit` ou Ctrl-D | Quitter |
| `/model` | Changer de modèle (sonnet / opus / haiku) |
| `/cost` | Voir le coût de la session |
| `/compact` | Compacter le contexte (utile pour les longues sessions) |
| `/review` | Demande à Claude de review tes changements |
| `/init` | Crée un fichier `CLAUDE.md` dans le projet (instructions perso) |

### Sessions persistantes

```bash
❯ ccr                             # alias pour `claude --resume`
# Reprend la dernière session du dossier courant
```

### Le fichier CLAUDE.md

À la racine de ton projet, crée un `CLAUDE.md` qui explique les conventions du projet à Claude. Exemple :

```markdown
# Project: My API

- Language: Python 3.12 with FastAPI
- Package manager: uv
- Tests: pytest, run with `uv run pytest`
- Style: ruff format, check with `uv run ruff check`
- Commit messages: Conventional Commits (feat:, fix:, etc.)

Don't commit without running tests first.
```

Claude Code lit ce fichier automatiquement et respecte tes règles.

### Mode "planning"

Avant de coder, tu peux demander :

```
> plan how to add user authentication (don't code yet)
```

Claude fait un plan, tu valides, puis tu dis "ok, go".

### Limites

- Les appels Claude coûtent des tokens. Si tu ouvres une grosse codebase en demandant "expliquer ce projet", tu peux cramer vite.
- Claude Code ne fait rien sans te demander (modifier un fichier, run une commande) — il te montre un diff et tu confirmes.

### Workflow type

```bash
❯ cd ~/projects/api
❯ cc
> I want to add a /users/me endpoint that returns the current user

# Claude te propose un plan, regarde les fichiers, propose les edits
# Tu dis "yes" à chaque modification qu'il veut appliquer
# Il lance les tests, corrige si besoin
# Tu quittes avec Ctrl-D ou /exit
```

---

## 🎯 Workflow type Python + Docker

```bash
# Nouveau projet FastAPI
❯ mkdir mon_api && cd mon_api
❯ uv init
❯ uv add fastapi uvicorn
❯ uv add --dev pytest httpx ruff

# direnv pour auto-activation
❯ cat > .envrc <<EOF
source .venv/bin/activate
export DATABASE_URL="postgres://localhost/mydb"
EOF
❯ direnv allow

# Dockerfile minimal
❯ cat > Dockerfile <<EOF
FROM python:3.12-slim
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen --no-dev
COPY . .
CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0"]
EOF

# compose.yml
❯ cat > compose.yml <<EOF
services:
  api:
    build: .
    ports: ["8000:8000"]
    volumes: [".:/app"]
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: dev
EOF

❯ dc up --build
# L'API est sur http://localhost:8000
```

**Prochaine étape** : workflows avancés, tricks finaux, et un récap cheat-sheet.
