build: _build _firewall-https _firewall-reload

_build:
	docker-compose up --detach --build

_firewall-https:
	firewall-cmd --permanent --add-service=http{,s}

_firewall-smtp:
	firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="172.18.0.0/16" service name="smtp" accept'

_firewall-reload:
	firewall-cmd --reload

load_default_data:
	docker exec redmine bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=ja

set_mysql_config:
	docker exec -it mysql mysql_config_editor set --host=localhost --user=redmine --password

memcached: _cache_store _gemfile bundle_install restart

_cache_store:
	docker exec redmine sh -c "echo 'config.cache_store = :mem_cache_store, \"memcached\"' > config/additional_environment.rb"

_gemfile:
	docker exec redmine sh -c "echo \"gem 'dalli'\" > Gemfile.local"

start:
	docker-compose up --detach

stop:
	docker-compose stop

bundle_install:
	docker exec redmine bundle install

restart:
	docker exec redmine passenger-config restart-app /usr/src/redmine

down:
	docker-compose down

tail:
	docker-compose logs --follow

login:
	docker exec --interactive --tty --env LINES=$LINES --env COLUMNS=$COLUMNS redmine bash

backup: backup_db backup_files

backup_db:
	docker exec mysql mysqldump redmine | gzip > /var/www/redmine/backup/redmine_db_`date +%F`.sql.gz

backup_files:
	cd /var/www/redmine && tar cvf backup/redmine_files_`date +%F`.tar.gz files

make_volume_dir:
	mkdir -p /var/www/redmine
	semanage fcontext -a -t svirt_sandbox_file_t "$_(/.*)?"
	restorecon -Rv /var/www/redmine

install_docker:
	yum -y install epel-release
	yum -y install yum-{axelget,plugin-rpm-warm-cache,utils}
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	yum -y install docker-ce
	systemctl start docker
	systemctl enable docker

install_docker-compose:
	curl -L $(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'Linux-x86_64"' | grep url | cut -d'"' -f4) -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose

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
