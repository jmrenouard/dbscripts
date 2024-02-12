install_golang()
{
	local vers=${1:-"1.21.6"}
	rm -rf /var/tmp/go*.tar.gz
	curl -LSs https://go.dev/dl/go${vers}.linux-amd64.tar.gz > /var/tmp/go${vers}.linux-amd64.tar.gz
	sudo rm -rf /usr/local/go
	sudo tar -C /usr/local -xzf /var/tmp/go${vers}.linux-amd64.tar.gz
	export PATH=$PATH:/usr/local/go/bin
	echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh
}

install_vlang() 
{ 
	rm -rf /var/tmp/go*.tar.gz
  curl -LSs https://github.com/vlang/v/releases/latest/download/v_linux.zip > /var/tmp/v_linux.zip
	sudo rm -rf /usr/local/v
	sudo unzip -d /usr/local /var/tmp/v_linux.zip
	export PATH=$PATH:/usr/local/v
	echo 'export PATH=$PATH:/usr/local/v/
alias v="/usr/local/v/v"
' | sudo tee /etc/profile.d/vlang.sh
alias v="/usr/local/v/v"
sudo /usr/local/v/v up
}

install_zig()
{
	sudo snap install zig --classic --beta
}