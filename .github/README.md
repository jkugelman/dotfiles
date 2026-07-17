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

- **[delta]** — the Git pager, set as `core.pager`. `cargo install git-delta`,
  or `brew install git-delta` on macOS.
- **[git-revise]** — history-editing helper (`git revise`). `pipx install
  git-revise`.

[delta]: https://github.com/dandavison/delta
[git-revise]: https://github.com/mystor/git-revise


Docker
======

```sh
$ curl -fsSL https://get.docker.com | sudo sh
$ sudo systemctl enable docker
```
