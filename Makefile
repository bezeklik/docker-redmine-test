install:
	docker-compose up --detach --build

start:
	docker-compose up --detach

stop:
	docker-compose stop

down:
	docker-compose down

tail:
	docker-compose logs --follow

define HELP_TEXT
make start
make stop
make down
make tail
endef
export HELP_TEXT

help:
	@echo "$$HELP_TEXT"

.PHONY: install start stop down tail help
