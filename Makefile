# Maxmind account credentials to download geoip database
MAXMIND_ACCOUNT_ID = $(shell cat secrets/maxmind_account_id.txt)
MAXMIND_LICENSE_KEY = $(shell cat secrets/maxmind_license_key.txt)

# Mail server credentials for the mailbox that holds all the dmarc reports (rua and ruf)
MAIL_SERVER = $(shell cat secrets/mail_server.txt)
MAIL_SERVER_USER = $(shell cat secrets/mail_server_user.txt)
MAIL_SERVER_PASS = $(shell cat secrets/mail_server_pass.txt)
DMARC_REPORT_TARGET_EMAIL = $(shell cat secrets/dmarc_report_target_email.txt)

# These should not need to change
geoip_city_url = "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&account_id=$(MAXMIND_ACCOUNT_ID)&license_key=$(MAXMIND_LICENSE_KEY)&suffix=tar.gz"

parsedmarc_dashboard_url = "https://raw.githubusercontent.com/domainaware/parsedmarc/master/grafana/Grafana-DMARC_Reports.json"
dashboard_path = grafana/provisioning/dashboards/Grafana-DMARC_Reports.json

# Ease switching to podman
DOCKER = docker
DOCKER_COMPOSE = docker-compose

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
update-help:
	# elasticsearch has a hardcoded version in the dockerfile - update that first!

.PHONY:
fix-permissions:
	# FIXME need to ensure all the non read-only mounted directory have correct GID rw access to work inside the container
	# FIXME need to ensure all permissions are as expected inside the containers?
	# https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html
	# fixing group ids with chgrp may be the right approach?
	# only required on linux with rootless podman
	which podman && podman unshare chown 472:472 -R grafana/data
	which podman && podman unshare chown 472:472 -R grafana/provisioning

.PHONY:
update-parsedmarc: fix-permissions
	# update dashboard definition for grafana
	curl --silent $(parsedmarc_dashboard_url) --output $(dashboard_path)
	# update maxmind geoip database
	curl --silent $(geoip_city_url) | tar -xzvf - --directory parsedmarc --strip-components 1 '*/GeoLite2-Country.mmdb'
	# Updating parsedmarc.ini
	@cat parsedmarc/parsedmarc.ini.tpl \
		| sed -e "s/MAIL_SERVER_USER/$(MAIL_SERVER_USER)/g" \
		| sed -e "s/MAIL_SERVER_PASS/$(MAIL_SERVER_PASS)/g" \
		| sed -e "s/MAIL_SERVER/$(MAIL_SERVER)/g" \
		| sed -e "s/DMARC_REPORT_TARGET_EMAIL/$(DMARC_REPORT_TARGET_EMAIL)/g" \
		> parsedmarc/parsedmarc.ini
	# recreate container
	# $(DOCKER_COMPOSE) build --pull --no-cache parsedmarc
	$(DOCKER_COMPOSE) build --pull

.PHONY:
update-all-containers: update-help fix-permissions # update-parsedmarc
	# update container images
	$(DOCKER_COMPOSE) pull elasticsearch grafana

.PHONY:
clean:
	docker system prune --all --force
