#!/bin/bash

if [ -e config.sh ]
then
    echo 'using config.sh'
    source config.sh
fi

npm install

if [ "$NODE_ENV" == "production" ]
then
  forever app.js
else
  authbind node app.js
fi

