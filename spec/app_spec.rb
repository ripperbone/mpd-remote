
require_relative '../app'
require_relative './util'
require 'rspec'
require 'rack/test'
require 'ruby-mpd'


RSpec.describe 'MPD web interface' do
   include Rack::Test::Methods

   def app
      App
   end

   before(:all) do
      music_path = '/var/lib/mpd/music'
      Dir.chdir(music_path) do

         # create an empty mp3 file
         [{:file_name => "03. What's Up.mp3", :artist => "4 Non Blondes", :title => "What's Up?", :album => "Bigger, Better, Faster, More !", :genre => "Pop"},
         {:file_name => "03. Call Your Girlfriend.mp3", :artist => "Robyn", :title => "Call Your Girlfriend", :album => "Body Talk Pt. 3", :genre => "Dance"}
         ].each do |file_info|
            make_test_audio_file(file_info)
            expect(File).to exist(File.join(music_path, file_info[:file_name]))
         end

         @mpd = MPD.new
         @mpd.connect
         @mpd.update # update library with test music

      end
   end

   before(:each) do
      @mpd.clear
   end

   after(:all) do
      @mpd.disconnect
   end

   it 'adds a song to the current playlist by title' do
      expect(@mpd.queue.size).to be(0)
      get '/add/songs/title/what%27s%20up'
      expect(last_response).to be_ok
      expect(@mpd.queue.size).to be(1)
      expect(JSON.parse(last_response.body)).to include('state' => 'play')
      expect(JSON.parse(last_response.body)).to include('currentSong')
      expect(JSON.parse(last_response.body)['currentSong']).to include('title' => 'What\'s Up?')
      expect(JSON.parse(last_response.body)).to include('currentPlaylist')
      expect(JSON.parse(last_response.body)['currentPlaylist'].size).to be(1)
   end


   it 'returns the currently playing song details' do
      @mpd.where({title: "What's Up?"}, {add: true})
      @mpd.play

      get '/status'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to include('state' => 'play')
      expect(JSON.parse(last_response.body)).to include('currentSong')
      expect(JSON.parse(last_response.body)['currentSong']).to include('artist' => '4 Non Blondes')
      expect(JSON.parse(last_response.body)['currentSong']).to include('title' => 'What\'s Up?')
      expect(JSON.parse(last_response.body)['currentSong']).to include('album' => 'Bigger, Better, Faster, More !')
      expect(JSON.parse(last_response.body)['currentSong']).to include('genre' => 'Pop')
      expect(last_response.content_type).to eq('application/json')
   end

   it 'advances to the next song' do
      @mpd.where({title: "What's Up?"}, {add: true})
      @mpd.play
      @mpd.where({title: "Call Your Girlfriend"}, {add: true})
      @mpd.repeat=true # wrap to start of playlist
      next_song_id = @mpd.status[:nextsongid]
      expect(@mpd.status[:songid]).not_to eq(next_song_id)

      get '/next'
      expect(last_response).to be_ok
      expect(@mpd.status[:songid]).to eq(next_song_id)

   end


   it 'returns to the previous song' do
      @mpd.where({title: "What's Up?"}, {add: true})
      @mpd.play
      @mpd.where({title: "Call Your Girlfriend"}, {add: true})
      @mpd.repeat=true # wrap to start of playlist
      current_song_id = @mpd.status[:songid] # get current song id

      @mpd.next # advance to next song
      expect(@mpd.status[:songid]).not_to eq(current_song_id)

      get '/previous'
      expect(last_response).to be_ok
      expect(@mpd.status[:songid]).to eq(current_song_id)

   end


   it 'clears the playlist' do
      @mpd.where({title: "What's Up?"}, {add: true})
      expect(@mpd.queue.size).to be(1)

      get '/clear'
      expect(last_response).to be_ok
      expect(@mpd.queue.size).to be(0)

   end

   it 'returns not found if the URI is not defined' do
      get '/notexpected'
      expect(last_response.status).to be(404)
      expect(JSON.parse(last_response.body)).to include('message' => 'Not found')
      expect(last_response.content_type).to eq('application/json')
   end


end
