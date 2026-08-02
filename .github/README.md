Dotfiles
========

1.  ```sh
    $ git clone --bare git@github.com:jkugelman/dotfiles.git .dotfiles
    ```

    Clone the `dotfiles` repository from GitHub.

2.  ```sh
    $ dotfiles() { git --git-dir="$HOME"/.dotfiles --work-tree="$HOME" "$@"; }
    ```

    Set up an alias to send Git commands to `.dotfiles`, and also set `$HOME` as the
    work tree, while storing the Git state at `.dotfiles`.

3.  ```sh
    $ dotfiles checkout
    ```

    Copy the actual files from the `.dotfiles` repository to `$HOME`. Git pulls
    the tracked files out of the compressed database in the Git directory and
    places them in the work tree.

    `dotfiles checkout` might fail with a message like:

    > ```
    > error: The following untracked working tree files would be overwritten by checkout:
    >     .bashrc
    >     .gitignore
    > Please move or remove them before you can switch branches.
    > Aborting
    > ```

    Files on your computer might have identical locations and names as the files in
    the `.dotfiles` repo. Git doesn't want to overwrite your local files. Back up
    the files if they're useful; delete them if they aren't.

(These steps were adapted from [The best way to store your dotfiles: A bare Git
repository **EXPLAINED**][dotfiles-explained].)

[dotfiles-explained]: https://www.ackama.com/blog/posts/the-best-way-to-store-your-dotfiles-a-bare-git-repository-explained


Adding new files
================

Because `$HOME` is the work tree, `~/.gitignore` ignores everything by default
and opts in only to the directories whose new files should be tracked
automatically — `.claude/skills/`, `.vim/plugin/`, and friends. Without it a
`dotfiles add -A` would sweep the whole home directory into this public repo:
caches, shell history, and real secrets like `.cargo/credentials`.

Git ignores nothing that is already tracked, so this only governs *new* files.
Deliberately not opted in are `~/.ssh` (keys), `~/.local/bin` (mixed in with pip
and npm console shims), and new top-level dotfiles — tracking those should be a
conscious choice:

```sh
$ dotfiles add -f ~/.newrc
```

(The blog post above instead sets `status.showUntrackedFiles no`, which only
hides untracked files rather than protecting them, and has to be re-run by hand
on every machine because `--local` config isn't cloned.)


Command-line tools
==================

A few tools these configs reference aren't tracked in the repo — install them
per machine:

- **[bacon]** — background Rust checker, configured by
  `.config/bacon/prefs.toml`. `cargo install bacon`, or `brew install bacon` on
  macOS.
- **[delta]** — the Git pager, set as `core.pager`. `cargo install git-delta`,
  or `brew install git-delta` on macOS.
- **[git-revise]** — history-editing helper (`git revise`). `pipx install
  git-revise`.
- **[tree]** — directory-tree lister, wrapped by `common.shrc`. Ships with or
  packages for most Linux distros (`apt install tree`); `brew install tree` on
  macOS, which has no system copy.

[bacon]: https://dystroy.org/bacon/
[delta]: https://github.com/dandavison/delta
[git-revise]: https://github.com/mystor/git-revise
[tree]: https://oldmanprogrammer.net/source.php?dir=projects/tree


Terminal key mappings
=====================

Claude Code submits on Enter and inserts a newline on Shift+Enter. Terminals
transmit bytes rather than keypresses, though, and Enter is already a control
character — CR is 0x0d — with no modifier bits left to spare, so Shift+Enter
arrives indistinguishable from a bare Enter and the newline binding never
fires. Recovering the distinction takes a mapping in the terminal itself, the
last layer that still knows Shift was held: it sends ESC CR instead, which is
what Claude Code reads as "insert a newline".

`/terminal-setup` installs that mapping on the terminals it knows how to
configure, VS Code and iTerm2 among them. It does **not** cover Windows
Terminal — it classifies it as supporting Shift+Enter natively, which does not
hold over WSL. (It also identifies the terminal by `WT_SESSION`, which WSL may
not pass through even when `WSLENV` lists it, in which case Claude Code does
not recognize Windows Terminal at all.)

Windows Terminal therefore needs it by hand, in `settings.json` — an entry in
`actions` and the key that triggers it in `keybindings`:

```json
{ "command": { "action": "sendInput", "input": "\u001b\r" },
  "id": "User.sendInput.ShiftEnter" }

{ "id": "User.sendInput.ShiftEnter", "keys": "shift+enter" }
```

That file lives at
`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`,
and the terminal reloads it on save. A raw ESC byte is not valid inside a JSON
string, so the input has to be spelled as the `\u001b\r` escape above.

The mapping lives in the terminal's own settings, out of this repo's reach, so
it is per machine. Ctrl+J and a trailing backslash insert a newline with no
mapping at all, so a machine that hasn't been set up is inconvenient rather
than unusable.


Docker
======

```sh
$ curl -fsSL https://get.docker.com | sudo sh
$ sudo systemctl enable docker
```
