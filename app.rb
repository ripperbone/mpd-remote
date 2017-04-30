#!/usr/bin/env ruby

require 'sinatra/base'
require 'ruby-mpd'
require 'json'

class App < Sinatra::Base

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


   get '/' do
      songs_to_hash(@mpd.queue).to_json
   end

   get '/clear' do
      @mpd.clear
   end


   get '/status' do
      @mpd.status.to_json
   end

   get '/next' do
      @mpd.next
   end

   get '/previous' do
      @mpd.previous
   end
   
   get '/play' do
      @mpd.play
   end

   get '/play/:id' do
      @mpd.play params[:id]
   end

   get '/delete/:id' do
      @mpd.delete params[:id]
   end

   get '/artists' do
      @mpd.list(:artist).to_json
   end

   get '/genres' do
      @mpd.list(:genre).to_json
   end 

   get '/search/any/:query' do 
      songs_to_hash(@mpd.where({any: params[:query]})).to_json
   end
   
   get '/search/artist/:query' do
      
      songs_to_hash(@mpd.where(
         { artist: params[:query].gsub('<s>', '/')
         },
         { strict: ( params[:strict] == 'yes' ? true : false) 
      })).to_json
   end

   get '/search/genre/:query' do

      songs_to_hash(@mpd.where(
         { genre: params[:query].gsub('<s>', '/')
         },
         { strict: ( params[:strict] == 'yes' ? true : false)
      })).to_json
   end

   get '/search/title/:query' do
      songs_to_hash(@mpd.where({title: params[:query]})).to_json
   end
  
   get '/search/album/:query' do
      songs_to_hash(@mpd.where({album: params[:query]})).to_json
   end

   get '/add/any/:query' do
      @mpd.where({any: params[:query]}, {add: true})
   end

   get '/add/artist/:query' do
      @mpd.where(
         { artist: params[:query].gsub('<s>', '/') 
         },
         { add: true,
           strict: ( params[:strict] == 'yes' ? true : false) 
         })
   end
   
   get '/add/title/:query' do
      @mpd.where({title: params[:query]}, {add: true})
   end

   get '/add/album/:query' do
      @mpd.where({album: params[:query]}, {add: true})
   end

   get '/add/genre/:query' do
      @mpd.where(
      { genre: params[:query].gsub('<s>', '/')
      },
      { add: true,
        strict: ( params[:strict] == 'yes' ? true : false)
      })
   end
   
end


