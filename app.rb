#!/usr/bin/env ruby

require 'sinatra/base'
require 'ruby-mpd'
require 'json'

class App < Sinatra::Base

   before do
      content_type 'application/json'
   end


   def initialize
      super
      @mpd = MPD.new
      @mpd.connect
   end

   def songs_to_hash(songs)
      songs.each_with_index.map { |song, index| {:id => index,
                                     :artist => song.artist,
                                     :title => song.title,
                                     :album => song.album,
                                     :genre => song.genre,
                                     :file => song.file }}

   end

   # Returns the current songs in the playlist (queue)
   #
   # @return [String] JSON
   get '/' do
      songs_to_hash(@mpd.queue).to_json
   end

   # Clears the current playlist
   get '/clear' do
      @mpd.clear
   end

   # Returns the current state of the music server
   #
   # @return [String] JSON
   get '/status' do
      statusHash = @mpd.status
      puts statusHash[:song]
      # replace song id with the complete song details
      statusHash[:song] = songs_to_hash(@mpd.queue).reject { |song| song[:id] != statusHash[:song] }.first

      statusHash.to_json
      
   end

   # Change currently playing song to the next one in the playlist
   get '/next' do
      @mpd.next
   end

   # Change currently playing song to the previous one in the playlist
   get '/previous' do
      @mpd.previous
   end
  
   # Play the current song in the playlist 
   get '/play' do
      @mpd.play
   end

   # Play song in the playlist having the specified id
   get '/play/:id' do
      @mpd.play params[:id]
   end

   # Remove a song from the playlist having the specified id
   get '/delete/:id' do
      @mpd.delete params[:id]
   end

   # Get the available artists of the songs
   #
   # @return [String] JSON
   get '/list/artists' do
      if params[:limit].nil?
         @mpd.list(:artist).to_json
      else
         @mpd.list(:artist).sample(params[:limit].to_i).to_json
      end
   end

   

   # Get the available genres of the songs
   # 
   # @return [String] JSON
   get '/list/genres' do
      @mpd.list(:genre).to_json
   end 


   # Get the songs having any tags matching the query
   #
   # @return [String] JSON
   get '/search/any/:query' do 
      songs_to_hash(@mpd.where({any: params[:query]})).to_json
   end
  
   # Get the songs where artist matches the query
   #
   # @return [String] JSON 
   get '/search/artist/:query' do
      
      songs_to_hash(@mpd.where(
         { artist: params[:query].gsub('<s>', '/')
         },
         { strict: ( params[:strict] == 'yes' ? true : false) 
      })).to_json
   end

   # Get the songs where genre matches the query
   #
   # @return [String] JSON
   get '/search/genre/:query' do

      songs_to_hash(@mpd.where(
         { genre: params[:query].gsub('<s>', '/')
         },
         { strict: ( params[:strict] == 'yes' ? true : false)
      })).to_json
   end

   # Get the songs where title matches the query
   #
   # @return [String] JSON
   get '/search/title/:query' do
      songs_to_hash(@mpd.where({title: params[:query]})).to_json
   end
  
   # Get the songs where album matches the query
   #
   # @return [String] JSON
   get '/search/album/:query' do
      songs_to_hash(@mpd.where({album: params[:query]})).to_json
   end

   # Add songs to the playlist where any tag matches the query
   get '/add/any/:query' do
      @mpd.where({any: params[:query]}, {add: true})
   end

   # Add songs to the playlist where artist matches the query
   get '/add/artist/:query' do
      @mpd.where(
         { artist: params[:query].gsub('<s>', '/') 
         },
         { add: true,
           strict: ( params[:strict] == 'yes' ? true : false) 
         })
   end

   # Add songs to the playlist where title matches the query
   get '/add/title/:query' do
      @mpd.where({title: params[:query]}, {add: true})
   end

   # Add songs to the playlist where album matches the query
   get '/add/album/:query' do
      @mpd.where({album: params[:query]}, {add: true})
   end

   # Add songs to the playlist where genre matches the query
   get '/add/genre/:query' do
      @mpd.where(
      { genre: params[:query].gsub('<s>', '/')
      },
      { add: true,
        strict: ( params[:strict] == 'yes' ? true : false)
      })
   end
   
end


