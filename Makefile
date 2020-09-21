# Maxmind account credentials to download geoip database
MAXMIND_ACCOUNT_ID := $(shell cat secrets/maxmind_account_id.txt)
MAXMIND_LICENSE_KEY := $(shell cat secrets/maxmind_license_key.txt)

# Mail server credentials for the mailbox that holds all the dmarc reports (rua and ruf)
MAIL_SERVER := $(shell cat secrets/mail_server.txt)
MAIL_SERVER_USER := $(shell cat secrets/mail_server_user.txt)
MAIL_SERVER_PASS := $(shell cat secrets/mail_server_pass.txt)
DMARC_REPORT_TARGET_EMAIL := $(shell cat secrets/dmarc_report_target_email.txt)

# These should not need to change
geoip_city_url := "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&account_id=$(MAXMIND_ACCOUNT_ID)&license_key=$(MAXMIND_LICENSE_KEY)&suffix=tar.gz"

parsedmarc_dashboard_url := "https://raw.githubusercontent.com/domainaware/parsedmarc/master/grafana/Grafana-DMARC_Reports.json"
dashboard_path := grafana/provisioning/dashboards/Grafana-DMARC_Reports.json

# Ease switching to podman
DOCKER_COMPOSE = docker-compose

.DEFAULT:
just-run-the-damn-thing: update-parsedmarc start
	
.PHONY:
podman:
	# switch to using podman-compose
	$(eval DOCKER_COMPOSE=podman-compose)
	# ensure podman is able to resolve dns queries
	$(eval export GODEBUG:=netdns=go)

.PHONY: # Trigger dmarc parsing using this, probably from a cron job
parsedmarc:
	$(DOCKER_COMPOSE) start parsedmarc

.PHONY:
start:
	$(DOCKER_COMPOSE) up -d

.PHONY:
stop:
	$(DOCKER_COMPOSE) down

.PHONY:
logs:
	$(DOCKER_COMPOSE) logs --follow

.PHONY:
fix-permissions:
	-which podman && podman unshare chown -R 472:472 grafana/data
	-which podman && podman unshare chown -R 1000:1000 elasticsearch

.PHONY:
update-parsedmarc: fix-permissions
	# update dashboard definition for grafana
	curl --silent $(parsedmarc_dashboard_url) --output $(dashboard_path)
	# update maxmind geoip database
	curl --silent $(geoip_city_url) | tar -xzvf - --directory parsedmarc --strip-components 1 '*/GeoLite2-Country.mmdb'
	# Updating parsedmarc.ini
	MAIL_SERVER="$(MAIL_SERVER)" MAIL_SERVER_USER="$(MAIL_SERVER_USER)" \
	MAIL_SERVER_PASS="$(MAIL_SERVER_PASS)" DMARC_REPORT_TARGET_EMAIL="$(DMARC_REPORT_TARGET_EMAIL)" \
		parsedmarc/template.py parsedmarc/parsedmarc.ini.tpl \
		> parsedmarc/parsedmarc.ini
	# recreate container
	$(DOCKER_COMPOSE) build --pull

.PHONY:
update-help:
	# elasticsearch has a hardcoded version in the docker-compose.yml - update that first!

.PHONY:
update-all-containers: update-help fix-permissions
	# update container images
	$(DOCKER_COMPOSE) pull

.PHONY:
clean:
	docker system prune --all --force
