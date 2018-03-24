build: _build _firewall-https _firewall-reload

_build:
	docker-compose up --detach --build

_firewall-https:
	firewall-cmd --permanent --add-service=http{,s}

_firewall-reload:
	firewall-cmd --reload

load_default_data:
	docker exec redmine bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=ja

set_mysql_config:
	docker exec -it mysql mysql_config_editor set --host=localhost --user=redmine --password

memcached: _cache_store _gemfile install restart

_cache_store:
	docker exec redmine sh -c "echo 'config.cache_store = :mem_cache_store, \"memcached\"' > config/additional_environment.rb"

_gemfile:
	docker exec redmine sh -c "echo \"gem 'dalli'\" > Gemfile.local"

start:
	docker-compose up --detach

stop:
	docker-compose stop

install:
	docker exec redmine bundle install

restart:
	docker exec redmine passenger-config restart-app /usr/src/redmine

down:
	docker-compose down

tail:
	docker-compose logs --follow

backup: backup_db backup_files

backup_db:
	docker exec mysql mysqldump redmine | gzip > /var/www/redmine/backup/redmine_db_`date +%F`.sql.gz

backup_files:
	cd /var/www/redmine && tar cvf backup/redmine_files_`date +%F`.tar.gz files

define HELP_TEXT
make start
make stop
make down
make tail
endef
export HELP_TEXT

help:
	@echo "$$HELP_TEXT"

.PHONY: build start stop restart down tail help
