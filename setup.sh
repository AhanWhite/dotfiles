#!/bin/bash

OH_MY_ZSH=$HOME"/.oh-my-zsh"
VUNDLE=$HOME"/.vim/bundle/Vundle.vim"
NEO_VUNDLE=$HOME"/.config/nvim/bundle/Vundle.vim"

IS_VIM=0
IS_NVIM=0  # neovim
IS_GIT=0
IS_BASH=0
IS_ZSH=0
IS_TMUX=0
IS_PIP=0
IS_SCREEN=0

read -p "CHOOSE SHELL (bash or zsh)? " _shell
# echo $choose_shell

if [ "$_shell" = "bash" ]; then
    unset IS_ZSH
elif [ "$_shell" = "zsh" ]; then
    unset IS_BASH
else
    echo "Invalid shell type, exit."
    exit 1
fi

# Pre check
check_installed() {
    softwares=("vim" "nvim" "git" "tmux" "pip" "screen")
    # bash >= 4.2
    if [ -v IS_BASH ]; then
        softwares+=( "bash" )
    else
        softwares+=( "zsh" )
    fi
    for sw in "${softwares[@]}"
    do
        flag="IS_${sw^^}"  # bash >= 4.0
        # Notice the semicolon
        # Dynamic naming:
        # - https://stackoverflow.com/a/13717788/1276501
        # - https://stackoverflow.com/a/18124325/1276501
        type ${sw} > /dev/null 2>&1 &&
            { printf -v "${flag}" 1; } ||
            { echo >&2 "[WARN] \`${sw}' is not installed, ignore it."; }
    done
}

create_symlinks() {
    # dotfile_src format such as zsh/zshrc or vim/vimrc
    dotfile_src=$1
    dotfile_dst=$2
    if [[ "$dotfile_dst" != /*  ]]; then
        # relative path
        dotfile_dst=$HOME/$dotfile_dst
    fi
    if [ -e $dotfile_dst ]; then
        if [ -h $dotfile_dst ]; then
            ln -sf $PWD/$dotfile_src $dotfile_dst
            echo "Update existed symlink $dotfile_dst"
        else
            echo "[WARN] Ignore due to $dotfile_dst exists and is not a symlink"
        fi
    else
        ln -sf $PWD/$dotfile_src $dotfile_dst
        echo "Create symlink $dotfile_dst"
    fi
}

#
# VIM
#
_install_vundle(){
    VUNDLE_DIR=$1
    if [ -d "${VUNDLE_DIR}" ]; then
        cd "${VUNDLE_DIR}"
        echo "Change directory to `pwd`"
        echo "${VUNDLE_DIR} exists. Git pull to update..."
        git pull
        cd - > /dev/null 2>&1
        echo "Change directory back to `pwd`"
    else
        echo "${VUNDLE_DIR} not exists. Git clone to create..."
        git clone https://github.com/gmarik/Vundle.vim.git ${VUNDLE_DIR}
        vim +PluginInstall +qall
    fi
}

config_vim() {
    _install_vundle $VUNDLE
    create_symlinks "vim/vimrc" ".vimrc"
}

#
# NEOVIM
#
config_nvim() {
    if [ -e $HOME/.vim ]; then
        create_symlinks "$HOME/.vim" "$HOME/.config/nvim"
    else
        _install_vundle $NEO_VUNDLE
    fi
    create_symlinks "vim/vimrc" "$HOME/.config/nvim/init.vim"
}


#
# GIT
#
config_git() {
    create_symlinks "git/gitconfig" ".gitconfig"
    create_symlinks "git/tigrc" ".tigrc"
}


#
# BASH
#
_config_shell() {
    create_symlinks "common" ".common"
    create_symlinks "tools" "tools"
}

config_bash() {
    create_symlinks "bash/bashrc" ".bashrc"
    _config_shell
}


#
# ZSH
#
_install_oh_my_zsh() {
    if [ -d "${OH_MY_ZSH}" ]; then
        cd "${OH_MY_ZSH}"
        echo "Change directory to `pwd`"
        echo "${OH_MY_ZSH} exists. Git pull to update..."
        git pull
        cd - > /dev/null 2>&1
        echo "Change directory back to `pwd`"
    else
        echo "${OH_MY_ZSH} not exists. Install..."
        #git clone git@github.com:robbyrussell/oh-my-zsh.git ${HOME}/.oh-my-zsh
        #wget --no-check-certificate http://install.ohmyz.sh -O - | sh
        git clone https://github.com/robbyrussell/oh-my-zsh.git ${HOME}/.oh-my-zsh
    fi

    # install plugins
    zsh_autosuggestions="${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if ! [ -d "$zsh_autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git $zsh_autosuggestions
    fi
    zsh_completions="${HOME}/.oh-my-zsh/custom/plugins/zsh-completions"
    if ! [ -d "$zsh_completions" ]; then
        git clone https://github.com/zsh-users/zsh-completions.git $zsh_completions
    fi
}

config_zsh() {
    _install_oh_my_zsh
    create_symlinks "zsh/zshrc" ".zshrc"
    _config_shell
    # TODO: See ~/.oh-my-zsh/custom/
    create_symlinks "zsh/tanky.zsh-theme" "${OH_MY_ZSH}/themes/tanky.zsh-theme"
    # chsh -s `which zsh` # TODO: If zsh is an alias?
    echo "[INFO] Change your shell manually"
}


#
# TMUX
#
config_tmux(){
    create_symlinks "tmux/tmux.conf" ".tmux.conf"
    create_symlinks "tmux/tmux.sh" ".tmux.sh"
}


#
# PIP
#
config_pip(){
    [ -d ${HOME}/.pip ] || { mkdir $HOME/.pip; echo "mkdir $HOME/.pip"; }
    create_symlinks "pip/pip.conf" ".pip/pip.conf"
}


#
# SCREEN
#
config_screen() {
    create_symlinks "screen/screenrc" ".screenrc"
}

#
# CUSTOM
#
mkdir_custom() {
    [ -e ${HOME}/.custom ] || { mkdir $HOME/.custom; echo "mkdir $HOME/.custom"; }
}


check_installed
[ $IS_VIM -eq 1 ] && config_vim
[ $IS_NVIM -eq 1 ] && config_nvim
[ $IS_GIT -eq 1 ] && config_git
[ -v IS_BASH ] && [ "$IS_BASH" -eq 1 ] && config_bash
[ -v IS_ZSH ] && [ "$IS_ZSH" -eq 1 ] && config_zsh
[ $IS_TMUX -eq 1 ] && config_tmux
[ $IS_PIP -eq 1 ] && config_pip
[ $IS_SCREEN -eq 1 ] && config_screen
mkdir_custom

echo "[SETUP OK]"
