[general]
save_aggregate = True
save_forensic = True
output = /output/

[imap]
test = $ENABLE_TEST_MODE
host = $MAIL_SERVER
user = $MAIL_SERVER_USER
password = $MAIL_SERVER_PASS

[smtp]
host = $MAIL_SERVER
user = $MAIL_SERVER_USER
password = $MAIL_SERVER_PASS
from = $MAIL_SERVER_USER
to = $DMARC_REPORT_TARGET_EMAIL

[elasticsearch]
hosts = elasticsearch:9200
ssl = False
