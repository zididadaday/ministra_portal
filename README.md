# ministra_portal
Dockerized ministra_portal IPTV middleware (previously stalker_portal)

# requirements
running version of mysql with known password, user and ip (to connect)
when the compose.phar part runs you might run out of memory in php

# to build the Docker
Fetch the github repository
cd to folder path
Run command docker build -t ministra-docker .

# to run the docker
docker run -dp 8080:80 ministra-docker
(8080) is local machine port, (80) is port within docker