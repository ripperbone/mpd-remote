#!/usr/bin/env ruby

require 'json'
require 'rest-client'


# Party shuffle for MPD Remote. Picks a random genre and adds a few songs from that genre to the playlist. You can of course come up
# with more interesting criteria for generating playlists.


ADDRESS = 'localhost'
PORT = 8003

def resource
   RestClient::Resource.new "#{ADDRESS}:#{PORT}"
end


def genres
   JSON.parse(resource['/genres'].get.body).reject { |genre| genre.empty? or ['Holiday'].include? genre }
end

def search(genre)
   JSON.parse(resource["/songs/genre/#{URI.escape(genre.gsub('/', '_'))}"].get.body)
end

def add(genre)
   # since genres might contain slashes, represent those as underscores
   JSON.parse(resource["/add/songs/genre/#{URI.escape(genre.gsub('/', '_'))}/limit/25"].get.body)
end

def clear_current_playlist
   resource["/clear"].get
end

clear_current_playlist
puts add(genres.sample) # make a genre selection and then add songs of that genre.
