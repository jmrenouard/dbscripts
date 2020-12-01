
import glob
import os
defaults = {
    'generic_prefix'        : 'jmr',
    'genscript_name'        : 'generate_linodes.sh',
    'delscript_name'        : 'drop_linodes.sh',

    'nb_linode_vms'         : 6,
    'vm_generic_password'   : 'eixo1hoo7Goo7suu9v',
    'vm_generic_pubkey'     : './id_rsa.pub'

    'vm_name_1'             : 'app1',
    'vm_tags_1'             : 'application,formation,webapps',

    'vm_name_2'             : 'proxy',
    'vm_tags_2'             : 'proxy,formation',

    'vm_name_3'             : 'dbsrv1',
    'vm_tags_3'             : 'mariadb,db,database,formation',

    'vm_name_4'             : 'dbsrv2',
    'vm_tags_4'             : 'mariadb,db,database,formation',

    'vm_name_5'             : 'dbsrv3',
    'vm_tags_5'             : 'mariadb,db,database,formation',

    'vm_name_6'             : 'control1',
    'vm_tags_6'             : 'mariadb,db,database,formation',

}


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
