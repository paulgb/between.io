#!/bin/bash

if [ -e config.sh ]
then
    source config.sh
fi

npm install

authbind node app.js

