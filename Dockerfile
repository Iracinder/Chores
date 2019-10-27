FROM python:3.8-slim
WORKDIR /app

RUN apt-get update \
	&& apt-get install -y curl \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.0/binary-for-linux-64-bit.gz \
	&& gunzip elm.gz \
	&& chmod +x elm \
	&& mv elm /usr/local/bin/

COPY backend/Pipfile.lock backend/Pipfile /app/
RUN pip3 install --upgrade pip \
	&& pip3 install --no-cache pipenv \
	&& pipenv install --system --deploy

COPY frontend/ backend/ /app/

RUN elm make src/chores.elm --output=static/main.js

