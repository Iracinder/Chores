FROM arm32v7/python:3.8-slim
WORKDIR /app

RUN apt-get update \
	&& apt-get install -y curl \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
# Install nginx
RUN apt-get update \
    && apt-get install -y nginx-light \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/nginx/sites-enabled/*
# Install gunicorn and pytz
RUN pip install gunicorn
# Install elm
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.0/binary-for-linux-64-bit.gz \
	&& gunzip elm.gz \
	&& chmod +x elm \
	&& mv elm /usr/local/bin/
# Install python env
COPY backend/Pipfile.lock backend/Pipfile /app/
RUN pip3 install --upgrade pip \
	&& pip3 install --no-cache pipenv \
	&& pipenv install --system --deploy

# Copy conf files
COPY deploy/nginx.conf /etc/nginx/conf.d/
COPY deploy/gunicorn.conf /etc/
COPY deploy/start.sh /bin/
RUN chmod +x /bin/start.sh

# Compile elm
COPY frontend/ backend/ backend/static/index.html  /app/
#RUN elm make src/chores.elm --optimize --output=static/main.js
COPY backend/static/main.js static/

RUN chmod +x static
RUN chmod +r index.html static/main.js

