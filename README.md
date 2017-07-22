# dotfiles

Setup procedure for myself.

## Installation

1. install **Xcode**

1. install **Xcode Command Line Developer Tools**

   ```sh
   $ xcode-select -–install
   ```

1. install **Homebrew**

   ```sh
   $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
   $ brew doctor
   $ brew update # necessary if doctor says so.
   ```

1. git clone **dotfiles** and install git submodules

   (Maybe) First execution of `git` command, git is automatically installed.

   ```sh
   $ cd ~
   $ git clone git@github.com:ohbarye/dotfiles.git
   $ git submodule init
   $ git submodule update
   ```

1. setup  **dotfiles**

   ```sh
   $ sh ~/dotfiles/setup.sh
   ```

1. install **Apps** with Brewfile

   ```sh
   $ cd ~/dotfiles
   $ brew bundle
   ```
