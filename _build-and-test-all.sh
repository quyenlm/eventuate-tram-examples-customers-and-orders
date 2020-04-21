#! /bin/bash

set -e

dockerall="./gradlew ${DATABASE?}${MODE?}Compose"
dockercdc="./gradlew ${DATABASE?}${MODE?}cdcCompose"

${dockerall}Down
${dockercdc}Build
${dockercdc}Up

./wait-for-services.sh localhost "8099"

./gradlew -x :end-to-end-tests:test -x :snapshot-tests:test build

#Testing db cli
if [ "${DATABASE}" == "mysql" ]; then
  echo 'show databases;' | ./mysql-cli.sh -i
elif [ "${DATABASE}" == "postgres" ]; then
  echo '\l' | ./postgres-cli.sh -i
else
  echo "Unknown Database"
  exit 99
fi

${dockerall}Build
${dockerall}Up

./wait-for-services.sh localhost "8081 8082 8083"

#Testing mongo cli
echo 'show dbs' |  ./mongodb-cli.sh -i

./gradlew :end-to-end-tests:cleanTest :end-to-end-tests:test

${dockerall}Down
