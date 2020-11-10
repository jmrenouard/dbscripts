import os
import zipfile
import re
import fnmatch

excludes = ['.vagrant', '__pycache__', './*.zip', 'data/*', "ansible_vagrant.zip" ]

# transform glob patterns to regular expressions
excludes = r'|'.join([fnmatch.translate(x) for x in excludes]) or r'$.'

zf = zipfile.ZipFile("ansible_vagrant.zip", "w")

for dirname, subdirs, files in os.walk("."):
    dirname = [d for d in dirname if not re.match(excludes, d)]
    subdirs[:] = [d for d in subdirs if not re.match(excludes, d)]
    files[:] = [f for f in files if not re.match(excludes, f)]
    if len(dirname)>0 and len(files)>0:
	    print("DIRNAME: %s" % dirname[0])
	    print(files)
	    print(subdirs)
	    zf.write(dirname[0])
	    for filename in files:
	        zf.write(os.path.join(dirname[0], filename))
zf.close()