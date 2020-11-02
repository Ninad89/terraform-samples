#!/bin/bash
sudo amazon-linux-extras install nginx1
sudo service nginx start
sudo bash -c 'echo "<html> <head> <title>Test from amazon</title> </head> <body> <h3> This is Ninad </h3> </body> </html>" > /usr/share/nginx/html/index.html'