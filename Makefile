.PHONY: all

install:
	bin/bundle install

test:
	bin/rspec

server:
	bin/rackup config.ru


lint:
	bin/rubocop
