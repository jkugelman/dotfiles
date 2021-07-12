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
    $ dotfiles config --local status.showUntrackedFiles no
    ```

    Set a local configuration setting in `.dotfiles` to ignore untracked files.

4.  ```sh
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


Neovim
======

```sh
$ curl -L https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o ~/.local/bin/nvim
$ chmod +x ~/.local/bin/nvim
```


Docker
======

```sh
$ curl -fsSL https://get.docker.com | sudo sh
$ sudo systemctl enable docker
```
