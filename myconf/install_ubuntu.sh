#!/bin/bash

_SCRIPT_PATH="$(readlink -f $0)"
_DIR="$(dirname $_SCRIPT_PATH)"
echo "Conf dir: $_DIR"
#exit 0
set -x
# Install Oh My Tmux
(
	cd $HOME
	if [ ! -d "./.tmux" ]; then
		git clone https://github.com/gpakosz/.tmux.git
	else
		cd .tmux
		git pull
		cd -
	fi
	ln -s -f .tmux/.tmux.conf
	cp $_DIR/tmux.conf.local $HOME/.tmux.conf.local
)

# Install Oh My shell
(
	if [ -d "$HOME/.oh-my-bash" ]; then
		cd $HOME/.oh-my-bash/
		git pull

	else
		bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
	fi
)

# Install My Alias
cp $_DIR/bashrc $HOME/.bashrc
cp $_DIR/bashrc_local $HOME

# install Snapd
sudo apt update
sudo apt install -y snapd tmux fasd

sudo systemctl restart snapd

# Install Nvim & LazyVim
sudo systemctl enable snapd
sudo snap install nvim --classic
sudo snap install node --classic

cd /var/tmp
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
# required
mv ~/.config/nvim{,.bak}

# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}
(
	cd $HOME
	if [ ! -d "$HOME/.config/nvim" ]; then
		git clone https://github.com/LazyVim/starter $HOME/.config/nvim
	else
		cd $HOME/.config/nvim
		git pull
	fi
)
(
	cd $HOME
	git clone https://github.com/fish-shell/fish-shell.git
	cd fish-shell
	cmake .
	make
	make install
)

(
	sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
	wget -O- https://apt.releases.hashicorp.com/gpg |
		gpg --dearmor |
		sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
	gpg --no-default-keyring \
		--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
		--fingerprint

	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
		sudo tee /etc/apt/sources.list.d/hashicorp.list
	sudo apt update
	sudo apt-get install terraform
)
#pip install argcomplete
