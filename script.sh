#!/bin/bash

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if docker and docker-compose are installed, and install if necessary
if ! command_exists docker || ! command_exists docker-compose; then
    echo "Installing Docker and docker-compose..."
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    # Install docker-compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker and docker-compose installed successfully."
else
    echo "Docker and docker-compose are already installed."
fi

# Check if the site name is provided as a command-line argument
if [ $# -eq 0 ]; then
    echo "Please provide the site name as a command-line argument."
    exit 1
fi

site_name="$1"
echo "Creating WordPress site: $site_name"

# Create docker-compose.yml file
cat > docker-compose.yml <<EOL
version: '3'
services:
  wordpress:
    image: wordpress
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - ./wordpress:/var/www/html
  db:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: password
    volumes:
      - ./db_data:/var/lib/mysql
EOL

# Start the containers
docker-compose up -d

# Add entry to /etc/hosts
echo "127.0.0.1 $site_name" | sudo tee -a /etc/hosts

# Prompt the user to open the site in a browser
echo "Site created successfully. Open http://$site_name in your browser."

# Enable/disable site (stop/start containers)
if [ "$2" == "enable" ]; then
    echo "Enabling the site..."
    docker-compose start
    echo "Site enabled."
elif [ "$2" == "disable" ]; then
    echo "Disabling the site..."
    docker-compose stop
    echo "Site disabled."
fi

# Delete the site (delete containers and local files)
if [ "$2" == "delete" ]; then
    echo "Deleting the site..."
    docker-compose down
    echo "Site deleted."
fi


