#!/usr/bin/env python3
import logging
from logging.config import dictConfig
from flask import Flask, request
from markupsafe import escape

dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'wsgi': {
        'class': 'logging.StreamHandler',
        'stream': 'ext://flask.logging.wsgi_errors_stream',
        'formatter': 'default'
    }},
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi']
    }
})
app = Flask(__name__)


@app.route('/subpath/<subpath>', methods=['POST'])
def dump_request_data(subpath):
    app.logger.info("%s request,\nPath: %s\nHeaders:\n%s\n", request.method, str(request.path), str(request.headers))
    app.logger.info("Body: %s", request.get_data())

    return 'Subpath %s' % escape(subpath)


@app.route('/', methods=['POST'])
def basic():
    app.logger.info("basic paths\n")
    app.logger.info("%s request,\nPath: %s\nHeaders:\n%s\n", request.method, str(request.path), str(request.headers))
    app.logger.info("Body: %s", request.get_data())

    return 'pong'


@app.after_request
def print_header(response):
    app.logger.info("Headers: %s", response.headers)
    return response


if __name__ == '__main__':
    from sys import argv

    if len(argv) == 2:
        app.run(port=int(argv[1]), host="0.0.0.0")
    else:
        app.run(host="0.0.0.0")
