NAME = inception

all:
	cd srcs && docker-compose up -d --build

up:
	cd srcs %% && docker-compose up -d

down:
	cd srcs && docker-compose down -v

clean:
	cd srcs && docker-compose down -v --rmi all 

fclean: clean

re: fclean all

.PHONY: all up down clean fclean re