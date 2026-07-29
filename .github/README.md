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

`.claude/keybindings.json` binds Enter to insert a newline and Ctrl+Enter to
submit, matching how Slack is configured. Terminals transmit bytes rather than
keypresses, and Enter is already a control character — CR is 0x0d, which is
Ctrl+M — so no byte is left over to mean Ctrl+Enter, and it arrives
indistinguishable from a bare Enter. Each terminal has to be told to send it as
CSI 13;5u instead, which Claude Code matches whether or not the Kitty keyboard
protocol has been negotiated. `/terminal-setup` makes the same move when it
maps Shift+Enter to ESC CR, so the technique is ordinary; what matters is that
submitting never rests on it alone.

Ctrl+Q submits with no mapping at all, on any terminal — Ctrl+letter rides the
ASCII control range, the same always-available vocabulary that carries Enter. A
machine that hasn't been set up is inconvenient, not unusable.

The mappings live in each application's own settings, out of this repo's reach,
so they are per machine:

- **iTerm2** — Settings > Profiles > Keys > Key Bindings. Add Cmd+Enter, action
  "Send Hex Codes", value `0x1b 0x5b 0x31 0x33 0x3b 0x35 0x75`.

- **Windows Terminal** — in `settings.json`, an entry in `actions` and the
  key that triggers it in `keybindings`:

  ```json
  { "command": { "action": "sendInput", "input": "\u001b[13;5u" },
    "id": "User.sendInput.CtrlEnter" }

  { "id": "User.sendInput.CtrlEnter", "keys": "ctrl+enter" }
  ```

- **VS Code** — in `keybindings.json`. Keybindings are a client-side setting,
  so over a remote (WSL, SSH) this belongs on the local machine rather than the
  remote:

  ```json
  { "key": "ctrl+enter", "command": "workbench.action.terminal.sendSequence",
    "args": { "text": "\u001b[13;5u" }, "when": "terminalFocus" }
  ```


Docker
======

```sh
$ curl -fsSL https://get.docker.com | sudo sh
$ sudo systemctl enable docker
```
