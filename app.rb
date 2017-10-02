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

   def get_status
      statusHash = @mpd.status
      playlist = songs_to_hash(@mpd.queue)
      # replace song id with the complete song details
      statusHash[:song] = playlist.reject { |song| song[:id] != statusHash[:song] }.first
      statusHash[:playlist] = playlist
      return statusHash
   end


   get '/' do
      get_status.to_json
   end

   get '/status' do
      get_status.to_json
   end

   post '/clear' do
      @mpd.clear
   end

   post '/next' do
      @mpd.next
   end

   post '/previous' do
      @mpd.previous
   end
  
   post '/play' do
      @mpd.play
   end

   post '/play/:id' do
      begin 
         @mpd.play params[:id]
      rescue MPD::ServerArgumentError => ex
         halt 400, ex.to_json
      end 
   end

   delete '/song/:id' do
      begin 
         @mpd.delete params[:id]
      rescue MPD::ServerArgumentError => ex
         halt 400, ex.to_json
      end
      get_status.to_json
   end


   # list...


   get '/artists' do
      @mpd.list(:artist).to_json
   end

   get '/genres' do
      @mpd.list(:genre).to_json
   end 

   get '/albums' do
      @mpd.list(:album).to_json
   end


   # search...


   get '/songs/any/:query' do 
      songs_to_hash(@mpd.where({any: params[:query]})).to_json
   end
  
   get '/songs/artist/:query' do
      songs_to_hash(@mpd.where({ artist: params[:query] })).to_json
   end

   get '/songs/genre/:query' do
      songs_to_hash(@mpd.where({ genre: params[:query]})).to_json
   end

   get '/songs/title/:query' do
      songs_to_hash(@mpd.where({title: params[:query]})).to_json
   end
  
   get '/songs/album/:query' do
      songs_to_hash(@mpd.where({album: params[:query]})).to_json
   end


 
   # add...

   post '/songs/random/:size' do
      @mpd.songs.map{ |song| song.file}.reject{ |song| song.nil? }.sample(params[:size].to_i).each{ |song| @mpd.add(song) }
      get_status.to_json
   end

   post '/songs/any/:query' do
      @mpd.where({any: params[:query]}, {add: true})
      get_status.to_json
   end

   post '/songs/artist/:query' do
      @mpd.where({artist: params[:query]}, {add: true})
      get_status.to_json
   end

   post '/songs/title/:query' do
      @mpd.where({title: params[:query]}, {add: true})
      get_status.to_json
   end

   post '/songs/album/:query' do
      @mpd.where({album: params[:query]}, {add: true})
      get_status.to_json
   end

   post '/songs/genre/:query' do
      @mpd.where({genre: params[:query]}, {add: true})
      get_status.to_json
   end



   not_found do
      "Not found".to_json
   end
   
end


