# dotfiles

Setup procedure for myself.

1. Install **Xcode Command Line Developer Tools**

  ```sh
  $ xcode-select –install
  ```

1. Install **Homebrew**

  ```sh
  $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  $ brew doctor
  ```

1. git clone **dotfiles**

  (Maybe) First execution of `git` command, git is automatically installed.

  ```sh
  $ cd ~
  $ git clone https://github.com/ohbarye/dotfiles.git
  ```

1. setup  **dotfiles**

  ```sh
  $ cd ~/dotfiles
  $ sh setup.sh
  ```

1. Install **Apps** with Brewfile

  ```sh
  $ brew tap Homebrew/brewdler
  $ brew ~/dotfiles/brewdle
  ```
