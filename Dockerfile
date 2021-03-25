FROM ubuntu:latest

USER root

RUN apt update && apt install --no-install-recommends \
   mpd mpc ruby wget vim ffmpeg sudo -y


RUN useradd --home-dir /var/lib/jenkins --no-create-home -u 135 jenkins

RUN mkdir -p /run/mpd
RUN chown mpd:audio /run/mpd

COPY ./mpd.conf /etc/mpd.conf
RUN chmod 644 /etc/mpd.conf

RUN gem install bundler

RUN chmod -R 777 /var/lib/mpd/music
RUN chmod -R 777 /var/lib/mpd/playlists

RUN mkdir -p /var/lib/jenkins/workspace
RUN chown -R jenkins:jenkins /var/lib/jenkins

RUN echo "jenkins ALL= (mpd) NOPASSWD:/usr/bin/mpd" > /etc/sudoers.d/jenkins
