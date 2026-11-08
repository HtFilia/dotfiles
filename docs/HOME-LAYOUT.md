# Home folders

On a Linux workstation, the folders that Fedora and Debian create in `~`
(Desktop, Documents, Downloads, Music, Pictures, Public, Templates, Videos)
are replaced by three lowercase ones under `~/files`:

| XDG folder | Path |
|---|---|
| Downloads | `~/files/downloads` |
| Documents | `~/files/docs` |
| Pictures, Music, Videos | `~/files/media` |
| Desktop | `~/.local/share/desktop` (hidden; Plasma needs one) |
| Templates, Public | turned off (`$HOME/`) |

`~/.config/user-dirs.dirs` sets the paths, and `~/.config/user-dirs.conf`
(`enabled=False`) stops `xdg-user-dirs-update` from recreating the default
folders at login. Firefox, Spectacle and file dialogs follow the new paths
after the next login.

`chezmoi apply` creates the new folders and removes the default ones that are
empty. A default folder that still holds files stays, with a note to move its
contents under `~/files`. The Dolphin sidebar (`~/.local/share/user-places.xbel`)
is not managed: Plasma rewrites it, so fix its entries there by hand.

To change the layout on one machine only, edit
`~/.config/user-dirs.dirs` and leave it out of chezmoi with
`chezmoi forget ~/.config/user-dirs.dirs`.
