LOCAL_DIR="${1:-$HOME/.local}"
WORKSPACE_DIR="${2:-${PWD}/workspace}"
PROJECT_DIR=${PWD}
DOTFILES=$PROJECT_DIR/dotfiles

source utils.sh

source ../env.sh

if [ -d $WORKSPACE_DIR ]; then
  rm $WORKSPACE_DIR
fi

# Check the architecture and set the ARCH variable.
machine_arch=$(uname -m)
if [[ "$machine_arch" == "aarch64" ]]; then
  ARCH="arm64"
elif [[ "$machine_arch" == "x86_64" ]]; then
  ARCH="x86_64"
else
  # Handle other architectures or unknown cases.
  ARCH="unknown"
  echo "Warning: Unknown architecture detected: $machine_arch" >&2  # Output to stderr
  exit 1
fi

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
    -p https://github.com/zsh-users/zsh-syntax-highlighting \
    -a 'export TZ="Asia/Seoul"' \
    -a 'alias gauca="git add -u; git commit --amend"' \
    -a 'alias gfrhu="git fetch; git reset --hard @{u}"' \
    -a 'alias gaucapf="gauca; git push -f"' \
    -a 'alias gaucm="git add -u; git commit -m"' \
    -a 'export PATH='"$LOCAL_DIR"/bin':$PATH' \
    -a 'export MANPATH='"$LOCAL_DIR"/share/man:'$MANPATH' \
    -a 'export SHELL=$(which zsh)' \
    -a 'if [[ -n "$TMUX" ]]; then export TERM="xterm-kitty"; fi'
    
  chsh -s $(which zsh)
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

  TMUX_VER=${TMUX_VER:-"3.5a"}

  pushd $WORKSPACE_DIR
  if [ -d ~/.zsh/pure ]; then
    rm -rf ~/.zsh/pure
  fi

  TMUX_FILE=tmux-${TMUX_VER}.tar.gz
  if [ -f "$TMUX_FILE" ]; then
    rm "$TMUX_FILE"
  fi
  
  wget https://github.com/tmux/tmux/releases/download/${TMUX_VER}/tmux-${TMUX_VER}.tar.gz
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
  git clone https://github.com/crissed53/lazyvim.dotfile.git -b raw ~/.config/nvim

  zsh -c "source ~/.zshrc && nvim --headless '+Lazy install' +MasonInstallAll +qall"
}

install_nvim() {
  pushd $WORKSPACE_DIR || exit
  APP_IMG=nvim-linux-${ARCH}.appimage
  if [ -d $APP_IMG ]; then
    rm $APP_IMG
  fi
  NVIM_VER=${NVIM_VER:-"v0.10.4"}
  curl -LO https://github.com/neovim/neovim/releases/download/$NVIM_VER/$APP_IMG
  chmod u+x $APP_IMG
  ./$APP_IMG --appimage-extract
  cp -rf squashfs-root "$LOCAL_DIR"/
  ln -sf "$LOCAL_DIR"/squashfs-root/AppRun "$LOCAL_DIR"/bin/nvim
  popd || exit
  add_if_not_exists 'alias vi=nvim' ~/.zshrc
  install_nvim_dotfile
}

install_langs() {
  # install node
  pushd $WORKSPACE_DIR
  NODE_VER=${NODE_VER:-"20"}
  curl -sfLS https://install-node.vercel.app/lts | bash -s -- -y --prefix $LOCAL_DIR

  # install rust
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  
  add_if_not_exists 'source $HOME/.cargo/env' ~/.zshrc

  # install go
  GO_VER=${GO_VER:-"1.23.4"}
  GO_TAR_FN=go${GO_VER}.linux-amd64.tar.gz
  wget https://go.dev/dl/${GO_TAR_FN} && tar -C $LOCAL_DIR -xzf ${GO_TAR_FN}
  add_if_not_exists 'export _GOPATH='"$LOCAL_DIR"/go ~/.zshrc
  add_if_not_exists 'export PATH=$PATH:$_GOPATH/bin' ~/.zshrc
  add_if_not_exists 'export GOBIN=$_GOPATH/bin' ~/.zshrc

  popd
}

install_plugins() {
  zsh <<'EOF'
source ~/.zshrc
source ./utils.sh
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
add_if_not_exists 'alias cd="z"' ~/.zshrc
add_if_not_exists 'eval "$(zoxide init zsh)"' ~/.zshrc

# install lazygit
go install github.com/jesseduffield/lazygit@latest
add_if_not_exists 'alias lg="lazygit"' ~/.zshrc

EOF
}

install_docker() {
  del_existing_package() {
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc;
      do apt-get remove $pkg;
    done
  }

  setup_docker_apt_repo() {
    # Add Docker's official GPG key:
    apt-get update
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
  }

  _install_docker() {
     apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  }

  del_existing_package
  setup_docker_apt_repo
  _install_docker
}

main() {
  set -exu
  mkdir -p "$WORKSPACE_DIR"

  echo "installing tmux..."
  install_tmux

  echo "install zsh..."
  install_zsh

  echo "setting up pure"
  install_pure

  echo "install uv and autoenv"
  install_zsh_uv_and_autoenv

  echo "install nvim"
  install_nvim

  install_langs
  install_plugins
  install_docker

  rm -rf "$WORKSPACE_DIR"
}

main
