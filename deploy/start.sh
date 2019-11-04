#! /bin/sh -e

nginx

gunicorn -c /etc/gunicorn.conf app:app
