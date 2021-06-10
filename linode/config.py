import glob
import os
import datetime
from shell import Shell

defaults_mariadb = {
    'datetime'              :'%s' % datetime.datetime.now(),
    'generic_prefix'        : 'jmr',
    'genscript_name'        : 'generate_linodes.sh',
    'provscript_name'       : 'provision_linodes.sh',
    'delscript_name'        : 'drop_linodes.sh',

    'nb_linode_vms'         : 6,
    'vm_generic_password'   : 'eixo1hoo7Goo7suu9v',
    'vm_generic_pubkey'     : './id_rsa.pub',

    'vm_name_1'             : 'app1',
    'vm_tags_1'             : 'application,webapps,linux',

    'vm_name_2'             : 'proxy',
    'vm_tags_2'             : 'proxy,linux',

    'vm_name_3'             : 'dbsrv1',
    'vm_tags_3'             : 'mariadb,database,linux',

    'vm_name_4'             : 'dbsrv2',
    'vm_tags_4'             : 'mariadb,database,linux',

    'vm_name_5'             : 'dbsrv3',
    'vm_tags_5'             : 'mariadb,database,linux',

    'vm_name_6'             : 'manager1',
    'vm_tags_6'             : 'control,management,linux'
}

defaults_elk = {
    'datetime'              :'%s' % datetime.datetime.now(),
    'generic_prefix'        : 'elk',
    'genscript_name'        : 'generate_linodes.sh',
    'provscript_name'       : 'provision_linodes.sh',
    'delscript_name'        : 'drop_linodes.sh',

    'nb_linode_vms'         : 3,
    'vm_generic_password'   : 'eixo1hoo7Goo7suu9v',
    'vm_generic_pubkey'     : './id_rsa.pub',

    'vm_name_1'             : 'elksrv',
    'vm_tags_1'             : 'application,webapps,linux',

    'vm_name_2'             : 'pgsrv1',
    'vm_tags_2'             : 'postgresql,postgres,database,linux',

    'vm_name_3'             : 'pgsrv2',
    'vm_tags_3'             : 'postgresql,postgres,database,linux'
}

defaults=defaults_elk

def merge_params(conf, params):
    result = defaults
    for arg in params:
        kv = arg.split('=')
        if len(kv) == 2:
            result[kv[0]] = kv[1]
    return result


def rmWildCard(pattern):
    for filePath in glob.glob(pattern):
        try:
            os.remove(filePath)
        except:
            print("Error while deleting file : ", filePath)


def get_public_ip(name):
    sh = Shell(verbose=False)
    sh.run("linode-cli linodes list --label "+name+ " --text")
    return sh.output()[1].split('\t')[6].split(' ')[0]


def get_private_ip(name):
    sh = Shell(verbose=False)
    sh.run("linode-cli linodes list --label "+name+ " --text")
    return sh.output()[1].split('\t')[6].split(' ')[1]