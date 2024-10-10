FROM python:3.11.3-slim-buster

RUN pip install flask

WORKDIR /usr/src/app

COPY . .

CMD [ "python3", "server.py", "8080" ]
