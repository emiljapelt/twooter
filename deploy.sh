#!/bin/bash

# Read from config file
. deploy.config


CONNECTION_STRING="Server=dbserver.twooter-network,1433;Database=Minitwit;Trusted_Connection=True;Integrated Security=false;User Id=SA;Password=$DB_PASSWORD"

echo ""
echo " *****************************************"
echo " * Updating system and installing docker *"
echo " *****************************************"
echo ""

apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"
apt update
apt-cache policy docker-ce
apt install -y docker-ce


echo ""
echo " **********************"
echo " * Authorizing docker *"
echo " **********************"
echo ""

docker login https://docker.pkg.github.com -u $GITHUB_USER -p $GITHUB_TOKEN

if [$? != 0]
then
  echo "Login failed"
  exit 1
fi

echo ""
echo " ***************"
echo " * Cleaning up *"
echo " ***************"
echo ""

cd minitwit/Api
rm -r bin
rm -r publish

echo ""
echo " *********************"
echo " * Building solution *"
echo " *********************"
echo ""

dotnet publish -c Release -o ./publish -v q

if [$? != 0]
then
  echo "Publish failed"
  exit 1
fi

docker build -q -t twooter .
docker tag twooter docker.pkg.github.com/themagicstrings/twooter/twooter
docker push docker.pkg.github.com/themagicstrings/twooter/twooter
# apt-get install sshpass

echo ""
echo " *********************************"
echo " * Securely connecting to server *"
echo " *********************************"
echo ""

# sshpass -p $4

ssh root@$HOST "
  echo \"\"
  echo \" *******************\"
  echo \" * Updating system *\"
  echo \" *******************\"
  echo \"\"
  apt update
  apt install -y apt-transport-https ca-certificates curl software-properties-common

  echo \"\"
  echo \" *********************\"
  echo \" * Installing docker *\"
  echo \" *********************\"
  echo \"\"

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"
  apt update
  apt-cache policy docker-ce
  apt install -y docker-ce

  echo \"\"
  echo \" **********************\"
  echo \" * Authorizing docker *\"
  echo \" **********************\"
  echo \"\"
  docker login https://docker.pkg.github.com -u $GITHUB_USER -p $GITHUB_TOKEN

  echo \"\"
  echo \" ***************\"
  echo \" * Cleaning up *\"
  echo \" ***************\"
  echo \"\"

  docker stop dbserver
  docker rm dbserver
  docker pull mcr.microsoft.com/mssql/server:2019-latest

  docker stop twooter-instance
  docker rm twooter-instance
  docker rmi docker.pkg.github.com/themagicstrings/twooter/twooter:latest

  docker network rm twooter-network
  docker network create twooter-network

  echo \"\"
  echo \" **********************\"
  echo \" * Starting DB Server *\"
  echo \" **********************\"
  echo \"\"

  docker run \
    -e \"ACCEPT_EULA=y\" \
    -e \"MSSQL_SA_PASSWORD=$DB_PASSWORD\" \
    -p 1433:1433 \
    --net twooter-network \
    --name dbserver \
    -h dbserver \
    -d \
    mcr.microsoft.com/mssql/server:2019-latest

  echo \"\"
  echo \" ********************\"
  echo \" * Starting Twooter *\"
  echo \" ********************\"
  echo \"\"

  docker pull docker.pkg.github.com/themagicstrings/twooter/twooter:latest -q
  docker run \
     --rm \
     -e \"ASPNETCORE_URLS=http://0.0.0.0:80\" \
     -e \"CONNECTION_STRING=$CONNECTION_STRING\" \
     -p 443:443 \
     -p 80:80 \
     --net twooter-network \
     --name twooter-instance \
     docker.pkg.github.com/themagicstrings/twooter/twooter:latest"
