.PHONY: all

all: deps_install gen_proto

deps_install:
	pip3 install protobuf
	pip3 install git+https://github.com/googleapis/python-eventarc-publishing.git@main

gen_proto:
	protoc --proto_path=proto --python_out=gen/ proto/spec.proto

clean:
	rm -rf gen/*
