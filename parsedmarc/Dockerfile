FROM python:alpine

RUN wget https://raw.githubusercontent.com/eficode/wait-for/master/wait-for -P /usr/local/bin/ \
    && chmod a+x /usr/local/bin/wait-for

RUN apk upgrade \
    && apk --no-cache add build-base libxml2-dev libxslt-dev

RUN python -m venv venv \
    && venv/bin/pip install --upgrade setuptools wheel pip \
    && venv/bin/pip install --use-feature=2020-resolver parsedmarc \
    && rm -rf /root/.cache/
