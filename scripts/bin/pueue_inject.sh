#!/bin/bash

for f in $*; do
        #sed -Ei 's/^REPLACE INTO/INSERT INTO/g' $f
        pueue add "mysql -f  <$f"
        echo "Adding $f to Pueue"
done
