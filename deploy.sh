#!/bin/bash

# $1 = github user
# $2 = access token
# $3 = server ip
# $4 = server password

read -r -p "Set MSSQL User: " MSSQL_USER
read -r -s -p "Set MSSQL DB Password: " MSSQL_SA_PASSWORD

CONNECTION_STRING="Server=dbserver,1433;Database=Minitwit;Trusted_Connection=True;Integrated Security=false;User Id=$MSSQL_USER;Password=$MSSQL_SA_PASSWORD"

apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"
apt update
apt-cache policy docker-ce
apt install -y docker-ce
docker login -u $1 -p $2
cd minitwit/Api
rm -r bin
rm -r publish
dotnet publish -c Release -o ./publish
docker build -t twooter .
docker tag twooter docker.pkg.github.com/themagicstrings/twooter/twooter
docker push docker.pkg.github.com/themagicstrings/twooter/twooter
# apt-get install sshpass

# sshpass -p $4
ssh root@$3 "
  apt update
  apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"
  apt update
  apt-cache policy docker-ce
  apt install -y docker-ce
  docker login https://docker.pkg.github.com -u $1 -p $2
  docker stop dbserver
  docker rm dbserver
  docker rmi mcr.microsoft.com/mssql/server:2019-latest
  docker stop twooter-instance
  docker rm twooter-instance
  docker rmi docker.pkg.github.com/themagicstrings/twooter/twooter:latest
  docker pull mcr.microsoft.com/mssql/server:2019-latest

  docker run \
    -e \"ACCEPT_EULA=y\" \
    -e \"MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD\" \
    -p 1433:1433 \
    --name dbserver \
    -h dbserver \
    -d \
    mcr.microsoft.com/mssql/server:2019-latest

  sleep 5
  docker pull docker.pkg.github.com/themagicstrings/twooter/twooter:latest
  docker run \
     --rm \
     -e ASPNETCORE_URLS=\"http://0.0.0.0:80\" \
     -e CONNECTION_STRING=\"$CONNECTION_STRING\" \
     -p 443:443 \
     -p 80:80 \
     --name twooter-instance \
     --link dbserver:dbserver \
     docker.pkg.github.com/themagicstrings/twooter/twooter:latest"
