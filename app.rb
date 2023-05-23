#!/usr/bin/env ruby

require 'sinatra/base'
require 'ruby-mpd'
require 'json'

class App < Sinatra::Base

   before do
      content_type 'application/json'

      response.headers['Access-Control-Allow-Origin'] = '*'

      if !@mpd.connected?
         @mpd.connect
      end
   end

   def alexa_request?
      request.env.has_key? 'HTTP_USER_AGENT' and request.env['HTTP_USER_AGENT'].include? 'python-requests'
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
      statusHash[:currentSong] = playlist.reject { |song| song[:id] != statusHash[:song] }.first
      statusHash[:currentPlaylist] = playlist
      return statusHash
   end

   def is_genre?(song, genre)
      return false if song.genre.nil?
      return song.genre.is_a?(Array) ? song.genre.any? { |song_genre| song_genre.downcase.eql?(genre.downcase) } : song.genre.downcase.eql?(genre.downcase)
   end


   get '/' do
      get_status.to_json
   end

   get '/status' do
      get_status.to_json
   end


   get '/clear' do
      @mpd.clear
      @mpd.status.to_json
   end

   get '/crop' do
      @mpd.queue.map { |song| song.id }.reject { |id| id.eql? @mpd.status[:songid] }.each { |id| @mpd.delete({id: id}) }
      get_status.to_json
   end

   get '/pause' do
      if @mpd.playing?
         @mpd.pause=true
      else
         # resume playing if already paused or stopped
         @mpd.play
      end
      get_status.to_json
   end

   get '/next' do
      @mpd.play unless @mpd.playing?
      @mpd.next
      get_status.to_json
   end

   get '/previous' do
      @mpd.play unless @mpd.playing?
      @mpd.previous
      get_status.to_json
   end

   get '/restart' do
      @mpd.play unless @mpd.playing?
      @mpd.seek(0)
      get_status[:currentSong].to_json
   end

   get '/play' do
      @mpd.play
      get_status[:currentSong].to_json
   end

   get '/play/:id' do
      begin
         @mpd.play params[:id]
      rescue MPD::ServerArgumentError => ex
         halt 400, ex.to_json
      end
   end

   get '/stop' do
      @mpd.stop
      @mpd.status.to_json
   end

   get '/remove/:id' do
      begin
         @mpd.delete params[:id]
      rescue MPD::ServerArgumentError => ex
         halt 400, ex.to_json
      end
      get_status.to_json
   end

   get '/volume/:percent' do
      begin
         @mpd.volume= params[:percent]
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

   get '/titles' do
      @mpd.songs.map { |song| song.title }.reject { |title| title.nil? }.to_json
   end

   get '/playlists' do
      @mpd.playlists.map { |playlist| playlist.name }.to_json
   end

   # search...

   get '/songs/artist/:query' do
      songs_to_hash(@mpd.where({ artist: params[:query] })).to_json
   end

   get '/songs/artist/:artist/title/:title' do
      songs_to_hash(@mpd.where({ artist: params[:artist], title: params[:title]})).to_json
   end

   get '/songs/artist/:artist/album/:album' do
      songs_to_hash(@mpd.where({ artist: params[:artist], album: params[:album]})).to_json
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

   get '/songs/composer/:query' do
      songs_to_hash(@mpd.where({composer: params[:query]})).to_json
   end

   get '/songs/playlist/:query' do
      @mpd.playlists.select { |playlist| playlist.name.include? params[:query] }.map { |playlist| { :playlist => playlist.name, :songs  => songs_to_hash(playlist.songs)} }.to_json
   end



   # add...

   get '/add/songs/random/:size' do
      @mpd.clear if alexa_request?
      @mpd.songs.map{ |song| song.file}.reject{ |song| song.nil? }.sample(params[:size].to_i).each{ |song| @mpd.add(song) }
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   # Add random songs but exclude some genres. @mpd.songs does not always contain genre information
   # so add songs to the queue first and then remove the songs we do not want to keep in the playlist.
   #
   get '/add/songs/party' do
      @mpd.clear if alexa_request?
      @mpd.songs.map { |song| song.file }.reject { |song| song.nil? }.sample(30).each { |song| @mpd.add(song) }
      @mpd.queue.select { |song| ['classical', 'jazz', 'holiday', 'comedy'].any? { |genre| is_genre?(song, genre) }}.each { |song| @mpd.delete({:id => song.id}) }
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   get '/add/songs/artist/:query' do
      @mpd.clear if alexa_request?
      @mpd.where({artist: params[:query]}, {add: true})
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   get '/add/songs/artist/:artist/title/:title' do
      @mpd.clear if alexa_request?
      @mpd.where({ artist: params[:artist], title: params[:title]}, {add: true})
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   get '/add/songs/artist/:artist/album/:album' do
      @mpd.clear if alexa_request?
      @mpd.where({ artist: params[:artist], album: params[:album]}, {add: true})
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   get '/add/songs/title/:query' do
      @mpd.clear if alexa_request?
      @mpd.where({title: params[:query]}, {add: true})
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   get '/add/songs/album/:query' do
      @mpd.clear if alexa_request?
      @mpd.where({album: params[:query]}, {add: true})
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   get '/add/songs/composer/:query' do
      @mpd.clear if alexa_request?
      @mpd.where({composer: params[:query]}, {add: true})
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   get '/add/songs/genre/:query/limit/:limit' do
      @mpd.clear if alexa_request?
      songs = @mpd.where({genre: params[:query].gsub('_', '/')})
      limit = songs.size > params[:limit].to_i ? params[:limit].to_i : songs.size
      songs.shuffle[0, limit].each { |song| @mpd.add(song) }
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   get '/add/songs/playlist/:query' do
      @mpd.clear if alexa_request?
      @mpd.playlists.select { |playlist| playlist.name.include? params[:query] }.each { |playlist| playlist.load }
      @mpd.play unless @mpd.playing?
      get_status.to_json
   end

   not_found do
      {"message" => "Not found"}.to_json
   end

end


