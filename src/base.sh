LOCAL_DIR="${1:-$HOME/local}"
WORKSPACE_DIR="${2:-${PWD}/workspace}"
PROJECT_DIR=${PWD}
DOTFILES=$PROJECT_DIR/dotfiles

source utils.sh

install_zsh() {
  OMZ_DIR="$HOME/.oh-my-zsh"

  if [ -d "$OMZ_DIR" ]; then
    rm -rf "$OMZ_DIR"
  fi

  sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
    -t "" \
    -p git \
    -p colorize \
    -p colored-man-pages \
    -p kubectl \
    -p tmux \
    -p poetry \
    -p helm \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting
}

set_zsh_alias() {
  add_if_not_exists 'export TZ="Asia/Seoul"' ~/.zshrc
  add_if_not_exists 'alias gauca="git add -u; git commit --amend"' ~/.zshrc
  add_if_not_exists 'alias gaucapf="gauca; git push -f"' ~/.zshrc
  add_if_not_exists 'alias gfrhu="git fetch; git reset --hard @{u}"' ~/.zshrc
  add_if_not_exists 'alias gaucm="git add -u; git commit -m"' ~/.zshrc
  add_if_not_exists 'alias vi=nvim' ~/.zshrc
  add_if_not_exists 'export PATH='"$LOCAL_DIR"/bin':$PATH' ~/.zshrc
  add_if_not_exists 'export MANPATH='"$LOCAL_DIR"/share/man:'$MANPATH' ~/.zshrc
  add_if_not_exists 'export SHELL=$(which zsh)' ~/.zshrc
}

install_tmuxrc() {
  pushd "$HOME"
  if [ -d .tmux ]; then
    rm -rf .tmux
  fi
  git clone https://github.com/gpakosz/.tmux.git
  ln -s -f .tmux/.tmux.conf
  popd
  cat "$DOTFILES"/tmux_conf.local >"${HOME}"/.tmux.conf.local
}

install_tmux_prerequisites() {
  apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config
}

install_pure() {
  # install pure
  if [ -d ~/.zsh/pure ]; then
    rm -rf ~/.zsh/pure
  fi
  mkdir -p "$HOME/.zsh"

  git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"

  add_if_not_exists 'fpath+=($HOME/.zsh/pure)' ~/.zshrc
  add_if_not_exists 'autoload -U promptinit; promptinit' ~/.zshrc
  add_if_not_exists 'prompt pure' ~/.zshrc
}

install_tmux() {
  install_tmux_prerequisites

  pushd $WORKSPACE_DIR
  wget https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz
  tar -zxf tmux-*.tar.gz
  pushd tmux-*/ || exit
  ./configure --prefix ${LOCAL_DIR}
  make && make install
  popd || exit
  install_tmuxrc
  popd
}

install_uv() {
  curl -LsSf https://astral.sh/uv/install.sh | sh
  add_if_not_exists 'export PATH=$HOME/.local/bin:$PATH' ~/.zshrc
}

install_autoenv() {
  FILEDIR="$HOME/.dotfiles/lib/zsh-autoenv"

  if [ -d "$FILEDIR" ]; then
    rm -rf "$FILEDIR"
  fi
  git clone https://github.com/Tarrasch/zsh-autoenv "$FILEDIR"
  add_block_if_not_exists "$DOTFILES"/autoenv "$HOME"/.zshrc
}

install_zsh_uv_and_autoenv() {
  # install uv, and zsh autoenv
  install_uv
  install_autoenv
}

install_nvim_dotfile() {
  NVIM_CONFIG_DIR="$HOME/.config/nvim"
  if [ -d "$NVIM_CONFIG_DIR" ]; then
    rm -rf "$NVIM_CONFIG_DIR"
  fi
  git clone https://github.com/crissed53/lazyvim.dotfile.git ~/.config/nvim

  zsh -c "source ~/.zshrc && nvim --headless '+Lazy install' +MasonInstallAll +qall"
}

install_nvim() {
  pushd $WORKSPACE_DIR || exit
  APP_IMG=nvim.appimage
  if [ -d $APP_IMG ]; then
    rm $APP_IMG
  fi
  curl -LO https://github.com/neovim/neovim/releases/latest/download/$APP_IMG
  chmod u+x $APP_IMG
  ./$APP_IMG --appimage-extract
  cp -rf squashfs-root "$LOCAL_DIR"/
  ln -sf "$LOCAL_DIR"/squashfs-root/AppRun "$LOCAL_DIR"/bin/nvim
  popd || exit
  install_nvim_dotfile
}

install_langs() {
  # install node
  pushd $WORKSPACE_DIR
  curl -sfLS https://install-node.vercel.app | bash -s -- 20 -y --prefix=/usr

  # install rust
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  add_if_not_exists 'source $HOME/.cargo/env' ~/.zshrc

  # install go
  wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz && tar -C $LOCAL_DIR -xzf go1.23.4.linux-amd64.tar.gz
  add_if_not_exists 'export PATH=$PATH:'"$LOCAL_DIR"/go/bin ~/.zshrc
  popd
}

install_plugins() {
  zsh <<'EOF'
source ~/.zshrc
# intsall fzf
if [ -d ~/.fzf ]; then
  rm -rf ~/.fzf
fi
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# install eza
cargo install eza zoxide dua-cli
add_if_not_exists 'alias ls="eza"' ~/.zshrc
add_if_not_exists 'alias ll="eza -lh"' ~/.zshrc
add_if_not_exists 'alias tree="eza --tree"' ~/.zshrc
add_if_not_exists 'eval "$(zoxide init zsh)"' ~/.zshrc

# install lazygit
go install github.com/jesseduffield/lazygit@latest
EOF
}

main() {
  set -exu
  mkdir -p "$WORKSPACE_DIR"

  #echo "installing tmux..."
  #install_tmux

  #echo "install zsh..."
  #install_zsh

  #echo "setting up zsh aliases... and rcs"
  #set_zsh_alias

  #echo "setting up pure"
  #install_pure

  #echo "install uv and autoenv"
  #install_zsh_uv_and_autoenv

  echo "install nvim"
  install_nvim

  install_langs
  install_plugins

  rm -rf "$WORKSPACE_DIR"
}

main
