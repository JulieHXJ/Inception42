NAME = inception

DATA_DIR = /home/xhuang/data
MARIADB_DATA = $(DATA_DIR)/mariadb
WORDPRESS_DATA = $(DATA_DIR)/wordpress

all:
	mkdir -p $(MARIADB_DATA)
	mkdir -p $(WORDPRESS_DATA)
	cd srcs && docker compose up -d --build

up:
	mkdir -p $(MARIADB_DATA)
	mkdir -p $(WORDPRESS_DATA)
	cd srcs && docker compose up -d

down:
	cd srcs && docker compose down 

clean:
	cd srcs && docker compose down --rmi all 

fclean: clean

re: fclean all

.PHONY: all up down clean fclean re