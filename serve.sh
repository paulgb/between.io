#!/bin/bash

if [ -e config.sh ]
then
    echo 'using config.sh'
    source config.sh
fi

npm install

forever app.js

