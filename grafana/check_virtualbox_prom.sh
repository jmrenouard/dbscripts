#!/bin/bash

# Variables
TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
TEXTFILE="$TEXTFILE_DIR/virtualbox_vms.prom"

# Créer le répertoire textfile si nécessaire
mkdir -p $TEXTFILE_DIR

# Initialiser le fichier textfile
echo "# HELP virtualbox_vm_status Status of VirtualBox VMs (1 = running, 0 = stopped)" > $TEXTFILE
echo "# TYPE virtualbox_vm_status gauge" >> $TEXTFILE

# Obtenir la liste des machines virtuelles
VM_LIST=$(VBoxManage list vms | awk '{print $1}' | tr -d '"')

# Vérifier l'état de chaque machine virtuelle et écrire dans le fichier textfile
for VM in $VM_LIST; do
  VM_STATUS=$(VBoxManage showvminfo "$VM" --machinereadable | grep -c 'VMState="running"')
  echo "virtualbox_vm_status{vm=\"$VM\"} $VM_STATUS" >> $TEXTFILE
done

echo "VirtualBox VMs status collected successfully."
