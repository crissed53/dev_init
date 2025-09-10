source ../env.sh
source utils.sh

LOCAL_DIR="${1:-$HOME/.local}"
WORKSPACE_DIR="${2:-${PWD}/workspace}"
PROJECT_DIR=$(dirname ${PWD})
DOTFILES=$PROJECT_DIR/config/dotfiles

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
    -a 'export EDITOR="nvim"' \
    -a 'export PATH='"$LOCAL_DIR"/bin':$PATH' \
    -a 'export MANPATH='"$LOCAL_DIR"/share/man:'$MANPATH' \
    -a 'export SHELL=$(which zsh)' \
    -a 'if [[ -n "$TMUX" ]]; then export TERM="xterm-kitty"; fi'
    
  sudo chsh -s "$(command -v zsh)" "${SUDO_USER:-$(id -un)}"
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
  sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config
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
  git clone https://github.com/crissed53/lazyvim.dotfile.git ~/.config/nvim

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
  # Source utils for helper functions
  source ./utils.sh
  
  pushd $WORKSPACE_DIR
  
  # Install Node.js
  echo "Installing Node.js..."
  NODE_VER=${NODE_VER:-"20"}
  curl -sfLS https://install-node.vercel.app/lts | bash -s -- -y --prefix $LOCAL_DIR

  # Install Rust
  echo "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  
  # Source Rust environment for this session
  source $HOME/.cargo/env
  add_if_not_exists 'source $HOME/.cargo/env' ~/.zshrc

  # Install Go
  echo "Installing Go..."
  GO_VER=${GO_VER:-"1.23.4"}
  GO_TAR_FN=go${GO_VER}.linux-amd64.tar.gz
  wget https://go.dev/dl/${GO_TAR_FN} && tar -C $LOCAL_DIR -xzf ${GO_TAR_FN}
  
  # Export Go environment for this session
  export _GOPATH="$LOCAL_DIR/go"
  export PATH="$PATH:$_GOPATH/bin"
  export GOBIN="$_GOPATH/bin"
  
  add_if_not_exists 'export _GOPATH='"$LOCAL_DIR"/go ~/.zshrc
  add_if_not_exists 'export PATH=$PATH:$_GOPATH/bin' ~/.zshrc
  add_if_not_exists 'export GOBIN=$_GOPATH/bin' ~/.zshrc

  popd
}

install_plugins() {
  # Source utils for helper functions
  source ./utils.sh
  
  # Install fzf
  if [ -d ~/.fzf ]; then
    rm -rf ~/.fzf
  fi
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all
}

install_rust_tools() {
  # Source cargo env
  [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
  
  # Install Rust-based tools
  cargo install eza zoxide dua-cli
  add_if_not_exists 'alias ls="eza"' ~/.zshrc
  add_if_not_exists 'alias ll="eza -lh"' ~/.zshrc
  add_if_not_exists 'alias tree="eza --tree"' ~/.zshrc
  add_if_not_exists 'alias cd="z"' ~/.zshrc
  add_if_not_exists 'eval "$(zoxide init zsh)"' ~/.zshrc
}

install_go_tools() {
  # Install Go-based tools
  go install github.com/jesseduffield/lazygit@latest
  add_if_not_exists 'alias lg="lazygit"' ~/.zshrc
}

install_docker() {
  del_existing_package() {
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc;
      do sudo apt-get remove $pkg;
    done
  }

  setup_docker_apt_repo() {
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
  }

  _install_docker() {
     sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  }

  del_existing_package
  setup_docker_apt_repo
  _install_docker
}

# Parallel installation helpers
wait_for_jobs() {
  local pids=("$@")
  local failed=0
  local completed=0
  local total=${#pids[@]}
  
  echo "Progress: 0/$total processes completed"
  
  while [ $completed -lt $total ]; do
    for i in "${!pids[@]}"; do
      local pid="${pids[$i]}"
      if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
        # Process has finished
        if wait "$pid"; then
          echo "Progress: $((++completed))/$total processes completed"
        else
          echo "Process $pid failed" >&2
          failed=1
          completed=$((completed + 1))
        fi
        pids[$i]="" # Mark as processed
      fi
    done
    
    # Don't busy-wait
    if [ $completed -lt $total ]; then
      sleep 1
    fi
  done
  
  return $failed
}

run_parallel_group() {
  local group_name="$1"
  shift
  local functions=("$@")
  local pids=()
  
  echo "Starting parallel group: $group_name"
  
  for i in "${!functions[@]}"; do
    local func="${functions[$i]}"
    echo "  → Starting $func in background..."
    (
      # Create unique workspace for each parallel process
      export WORKSPACE_DIR="${WORKSPACE_DIR}_${func}_$$"
      mkdir -p "$WORKSPACE_DIR"
      
      echo "[$$] $func: Starting with workspace $WORKSPACE_DIR..."
      if $func; then
        echo "[$$] $func: Completed successfully"
        rm -rf "$WORKSPACE_DIR" 2>/dev/null || true
      else
        echo "[$$] $func: Failed" >&2
        rm -rf "$WORKSPACE_DIR" 2>/dev/null || true
        exit 1
      fi
    ) &
    pids+=($!)
  done
  
  echo "Waiting for $group_name to complete..."
  if wait_for_jobs "${pids[@]}"; then
    echo "✓ $group_name completed successfully"
    return 0
  else
    echo "✗ $group_name had failures" >&2
    return 1
  fi
}

main() {
  set -exu
  mkdir -p "$WORKSPACE_DIR"

  # Phase 1: Sequential prerequisites (system packages + shell)
  echo "=== Phase 1: Core Prerequisites ==="
  
  echo "Installing tmux..."
  install_tmux

  echo "Installing zsh..."
  install_zsh

  echo "Setting up pure prompt..."
  install_pure

  echo "Installing uv and autoenv..."
  install_zsh_uv_and_autoenv

  # Phase 2: Parallel independent installations
  echo "=== Phase 2: Independent Components ==="
  run_parallel_group "Independent tools" "install_nvim" "install_docker"

  # Phase 3: Parallel language installations
  echo "=== Phase 3: Language Runtimes ==="  
  run_parallel_group "Language runtimes" "install_langs" "install_plugins"
  
  # Phase 4: Parallel tool installations (dependent on languages)
  echo "=== Phase 4: Language-specific Tools ==="
  run_parallel_group "Language tools" "install_rust_tools" "install_go_tools"

  echo "=== Setup Complete ==="
  rm -rf "$WORKSPACE_DIR"
}

main
