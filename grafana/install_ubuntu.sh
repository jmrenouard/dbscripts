sudo apt update

sudo apt install software-properties-common apt-transport-https wget -y
sudo rm -f /etc/apt/sources.list.d/grafana.list

sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg 

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# Updates the list of available packages
sudo apt-get update

PCK_LIST="grafana
prometheus
prometheus-node-exporter
prometheus-alertmanager
prometheus-pushgateway
prometheus-process-exporter
net-tools
jq
curl
vim
wget
htop
nload
nmap
git
unzip
zip
python3
python3-pip
python3-venv
python3-prometheus-client
pigz
pv
sysstat
bind9-dnsutils"

for pck in $PCK_LIST; do
	echo " * Installing $pck"
	echo "-----------------------------------"
	sudo apt-get install $pck -y
	
	echo "-----------------------------------"
done

sudo systemctl enable grafana-server
sudo systemctl start grafana-server
sudo systemctl enable prometheus
sudo systemctl start prometheus
