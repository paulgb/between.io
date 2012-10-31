#!/bin/bash

if [ -e config.sh ]
then
    echo 'using config.sh'
    source config.sh
fi

npm install

authbind node app.js

