# MPD Remote

Control your Music Server from a web interface. See [Music Player Daemon](https://www.musicpd.org).
Uses [ruby-mpd](https://github.com/archSeer/ruby-mpd) and [Sinatra](http://sinatrarb.com/).

- Do `gem install bundler --user` to get bundle

- Do `bundle install` to get all the required gems

- Do `./run` to start serving requests

## Running tests

- run `docker build -t mpd-remote-buildenv:latest .` to create a docker image.

- Start docker container (run from this directory)
   `docker run -it -v ${PWD}:/workspace mpd-remote-buildenv:latest /bin/bash`

- in the docker container, start MPD:
   `mpd`

- `cd /workspace`

- `bundle config set --local path vendor/bundle`

- `bundle install`

- `bundle exec rspec`
