FROM ubuntu:16.04

MAINTAINER Dominik Schulz <dominik.schulz@gauner.org>

RUN apt-get update --yes && apt-get install --yes --force-yes --no-install-recommends \
  build-essential \
  cpanminus \
  libconfig-std-perl \
  libmoose-perl \
  libnamespace-autoclean-perl \
  libmoosex-app-cmd-perl \
  libtest-pod-perl \
  make \
  perl \
  perltidy \
  && rm -rf /var/lib/apt/lists/*

RUN cpanm --force \
  Config::Yak \
  Job::Manager \
  Log::Tree \
  Sys::Bprsync \
  Sys::FS \
  Sys::RotateBackup \
  Sys::Run

ADD . /srv/revobackup
WORKDIR /srv/revobackup

RUN chmod +x /srv/revobackup/bin/revobackup.pl
ENV PERL5LIB /srv/revobackup/lib
