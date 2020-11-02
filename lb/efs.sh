#!/bin/bash
sudo yum install -y amazon-efs-utils
sudo mkdir efs
sudo mount -t efs -o tls fs-5e7f21af: ./efs
FILE=./efs/html/index.html
if [ -f "$FILE" ]; then
    echo "$FILE exists."
else 
    sudo mkdir -p ./efs/html
    sudo bash -c 'echo "<html> <head> <title>Test from amazon</title> </head> <body> <h3> This is Ninad </h3> </body> </html>" > ./efs/html/index.html'
fi
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install node
npm i serve -g
serve -n -s -l 8080 ./efs/html