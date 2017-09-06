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

   def return_subset_if_limit(list, params)
      return (params[:limit].nil? ? list : list.sample(params[:limit].to_i))
   end



   get '/' do
      get_status.to_json
   end

   get '/clear' do
      @mpd.clear
      get_status.to_json
   end

   get '/status' do
      get_status.to_json
   end

   get '/next' do
      @mpd.next
      get_status.to_json
   end

   get '/previous' do
      @mpd.previous
      get_status.to_json
   end
  
   get '/play' do
      @mpd.play
      get_status.to_json
   end

   get '/play/:id' do
      begin 
         @mpd.play params[:id]
      rescue MPD::ServerArgumentError => ex
         halt 400, ex.to_json
      end 
      get_status.to_json
   end

   get '/delete/:id' do
      begin 
         @mpd.delete params[:id]
      rescue MPD::ServerArgumentError => ex
         halt 400, ex.to_json
      end
      get_status.to_json
   end


   # /list/...


   get '/list/artists' do
      return_subset_if_limit(@mpd.list(:artist), params).to_json
   end

   get '/list/genres' do
      return_subset_if_limit(@mpd.list(:genre), params).to_json
   end 

   get '/list/albums' do
      return_subset_if_limit(@mpd.list(:album), params).to_json
   end


   # /search/...


   get '/search/any/:query' do 
      songs_to_hash(@mpd.where({any: params[:query]})).to_json
   end
  
   get '/search/artist/:query' do
      
      songs_to_hash(@mpd.where(
         { artist: params[:query] },
         { strict: ( params[:strict] == 'yes' ? true : false) 
      })).to_json
   end

   get '/search/genre/:query' do

      songs_to_hash(@mpd.where(
         { genre: params[:query] },
         { strict: ( params[:strict] == 'yes' ? true : false) })).to_json
   end

   get '/search/title/:query' do
      songs_to_hash(@mpd.where({title: params[:query]})).to_json
   end
  
   get '/search/album/:query' do
      songs_to_hash(@mpd.where({album: params[:query]})).to_json
   end



   # /add/...


   get '/add/any/:query' do
      @mpd.where({any: params[:query]}, {add: true})
      get_status.to_json
   end

   get '/add/artist/:query' do
      @mpd.where(
         { artist: params[:query] },
         { add: true, strict: ( params[:strict] == 'yes' ? true : false) })
      get_status.to_json
   end

   get '/add/title/:query' do
      @mpd.where({title: params[:query]}, {add: true})
      get_status.to_json
   end

   get '/add/album/:query' do
      @mpd.where({album: params[:query]}, {add: true})
      get_status.to_json
   end

   get '/add/genre/:query' do
      @mpd.where( { genre: params[:query] },
         { add: true, strict: ( params[:strict] == 'yes' ? true : false) })
      get_status.to_json
   end



   not_found do
      'Not found'.to_json
   end
   
end


