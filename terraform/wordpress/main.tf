terraform {
  required_providers {
    # We recommend pinning to the specific version of the Docker Provider you're using
    # since new versions are released frequently
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.1"
    }
  }
}
provider "docker" {
  //host = "unix:///var/run/docker.sock"
}

resource "docker_network" "private_network" {
  name = "wp_private_net"
}

resource "docker_volume" "wp_vol_db" {
  name = "wp_vol_db"
}

resource "docker_volume" "wp_vol_html" {
  name = "wp_vol_html"
}

resource "docker_image" "mariadb" {
    name = "docker.io/library/mariadb:latest"
}
resource "docker_image" "wordpress" {
    name = "docker.io/library/wordpress:latest"
}
resource "docker_container" "db" {
  name  = "db"
  image = "mariadb"
  restart = "always"
  network_mode = "wp_private_net"
  mounts {
    type = "volume"
    target = "/var/lib/mysql"
    source = "wp_vol_db"
  }

  env = [
     "MYSQL_ROOT_PASSWORD=rootpassword",
     "MYSQL_DATABASE=wordpress",
     "MYSQL_USER=exampleuser",
     "MYSQL_PASSWORD=examplepass"
  ]
}

resource "docker_container" "wordpress" {
  name  = "wordpress"
  image = "wordpress"
  restart = "always"
  network_mode = "wp_private_net"
  env = [
    "WORDPRESS_DB_HOST=db",
    "WORDPRESS_DB_USER=exampleuser",
    "WORDPRESS_DB_PASSWORD=examplepass",
    "WORDPRESS_DB_NAME=wordpress"
  ]
  ports {
    internal = "80"
    external = "8080"
  }
  mounts {
    type = "volume"
    target = "/var/www/html"
    source = "wp_vol_html"
  }
}
