
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
         {:file_name => "01. Daydreamer.mp3", :artist => "Adele", :title => "Daydreamer", :album => "19", :genre => "Pop"},
         {:file_name => "02. Best For Last.mp3", :artist => "Adele", :title => "Best For Last", :album => "19", :genre => "Pop"},
         {:file_name => "03. Chasing Pavements.mp3", :artist => "Adele", :title => "Chasing Pavements", :album => "19", :genre => "Pop"},
         {:file_name => "01. Hello.mp3", :artist => "Adele", :title => "Hello", :album => "25", :genre => "Pop"},
         {:file_name => "06. Can I Get It.mp3", :artist => "Adele", :title => "Can I Get It", :album => "30", :genre => "Pop"},
         {:file_name => "03. Call Your Girlfriend.mp3", :artist => "Robyn", :title => "Call Your Girlfriend", :album => "Body Talk Pt. 3", :genre => "Dance"},
         {:file_name => "04. Wintersong.mp3", :artist => "Sarah McLachlan", :title => "Wintersong", :album => "Wintersong", :genre => "Pop"},
         {:file_name => "11. In a Bleak Mid Winter.mp3", :artist => "Sarah McLachlan", :title => "In a Bleak Mid Winter", :album => "Wintersong", :genre => "Pop"}
         ].each do |file_info|
            create_audio_file(file_info)
            expect(File).to exist(File.join(music_path, file_info[:file_name]))
         end
      end

      Dir.chdir('/var/lib/mpd/playlists') do
         # create a playlist file
         File.open("holiday.m3u", "w") { |file| file.write(["04. Wintersong.mp3", "11. In a Bleak Mid Winter.mp3"].join("\n")) }
      end

      @mpd = MPD.new
      @mpd.connect
      @mpd.update # update library with test music

   end

   before(:each) do
      @mpd.clear
   end

   after(:all) do
      @mpd.disconnect
   end

   it 'adds a song to the current playlist by title' do
      expect(@mpd.queue.size).to eq(0)
      get '/add/songs/title/what%27s%20up'
      expect(last_response).to be_ok
      expect(@mpd.queue.size).to eq(1)
      expect(JSON.parse(last_response.body)).to include('state' => 'play')
      expect(JSON.parse(last_response.body)).to include('currentSong')
      expect(JSON.parse(last_response.body)['currentSong']).to include('title' => 'What\'s Up?')
      expect(JSON.parse(last_response.body)).to include('currentPlaylist')
      expect(JSON.parse(last_response.body)['currentPlaylist'].size).to eq(1)
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
      expect(@mpd.queue.size).to eq(1)

      get '/clear'
      expect(last_response).to be_ok
      expect(@mpd.queue.size).to eq(0)

   end

   it 'clears the playlist except for the current song' do
      @mpd.where({artist: "Adele"}, {add: true})
      expect(@mpd.queue.size).to eq(5)
      @mpd.play(2) # jump to middle of queue
      current_song_id = @mpd.status[:songid]

      get '/crop'
      expect(last_response).to be_ok
      expect(@mpd.queue.size).to eq(1)
      expect(@mpd.status[:songid]).to eq(current_song_id) #current song is still the same
   end

   it 'pauses and resumes playback' do
      @mpd.where({title: "Call Your Girlfriend"}, {add: true})
      expect(@mpd.paused?).to be(false)
      expect(@mpd.stopped?).to be(true)
      expect(@mpd.playing?).to be(false)

      # stopped -> playing
      get '/pause'
      expect(@mpd.paused?).to be(false)
      expect(@mpd.stopped?).to be(false)
      expect(@mpd.playing?).to be(true)

      # playing -> paused
      get '/pause'
      expect(@mpd.paused?).to be(true)
      expect(@mpd.stopped?).to be(false)
      expect(@mpd.playing?).to be(false)

      # paused -> playing
      get '/pause'
      expect(@mpd.paused?).to be(false)
      expect(@mpd.stopped?).to be(false)
      expect(@mpd.playing?).to be(true)
   end

   it 'removes a song from the playlist' do
      @mpd.where({artist: "Adele"}, {add: true})
      expect(@mpd.queue.size).to eq(5)
      get '/status'
      expect(last_response).to be_ok
      playlist = JSON.parse(last_response.body)["currentPlaylist"]

      get '/remove/2'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)["currentPlaylist"].size).to be(4)
      expect(JSON.parse(last_response.body)["currentPlaylist"]).to_not include(playlist[2])

   end

   it 'returns a bad request when removing a song that does not exist' do
      @mpd.where({artist: "Adele"}, {add: true})
      expect(@mpd.queue.size).to eq(5)
      get '/remove/9'
      expect(last_response.status).to be(400)
      expect(@mpd.queue.size).to eq(5)
   end

   it 'returns the list of playlists' do
      get '/playlists'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to include("holiday")
   end

   it 'returns the list of songs in the playlist' do
      get '/songs/playlist/holiday'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to include(include("playlist" => "holiday"))
      expect(JSON.parse(last_response.body)).to include(include("songs"))
      expect(JSON.parse(last_response.body).find { |playlist| playlist["playlist"].eql? "holiday" }["songs"]).to include(include("title" => "In a Bleak Mid Winter"))
      expect(JSON.parse(last_response.body).find { |playlist| playlist["playlist"].eql? "holiday" }["songs"]).to include(include("title" => "Wintersong"))
      expect(@mpd.queue.size).to eq(0) # songs should not be added
   end

   it 'adds the songs from the playlist to the queue playlist' do
      expect(@mpd.status[:state]).to eql(:stop)
      get '/add/songs/playlist/holiday'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to include("currentPlaylist")
      expect(JSON.parse(last_response.body)["currentPlaylist"].size).to eq(2)
      expect(@mpd.queue.size).to eq(2)
      expect(@mpd.status[:state]).to eql(:play)
   end

   it 'adds an assortment of songs to the queue but excludes some genres' do
      expect(@mpd.queue.size).to eq(0) # songs should not be added
      get '/add/songs/party'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)["currentPlaylist"].map { |song| song["genre"].downcase }).to include("pop")
      expect(JSON.parse(last_response.body)["currentPlaylist"].map { |song| song["genre"].downcase }).to include("dance")
      expect(JSON.parse(last_response.body)["currentPlaylist"].map { |song| song["genre"].downcase }).not_to include("holiday")
      expect(JSON.parse(last_response.body)["currentPlaylist"].map { |song| song["genre"].downcase }).not_to include("classical")
      expect(JSON.parse(last_response.body)["currentPlaylist"].map { |song| song["genre"].downcase }).not_to include("comedy")

   end

   it 'adds the songs for a request including artist and title' do
      get '/add/songs/artist/adele/title/hello'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to include("currentPlaylist")
      expect(JSON.parse(last_response.body)["currentPlaylist"][0]["title"]).to eq("Hello")
      expect(JSON.parse(last_response.body)["currentPlaylist"][0]["artist"]).to eq("Adele")
      expect(@mpd.queue.size).to eq(1)
   end

   it 'adds the songs for a request including artist and album' do
      get '/add/songs/artist/adele/album/19'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to include("currentPlaylist")
      expect(JSON.parse(last_response.body)["currentPlaylist"].map { |song| song["album"] }).to all(eq("19"))
      expect(JSON.parse(last_response.body)["currentPlaylist"].map { |song| song["artist"] }).to all(eq("Adele"))
   end

   it 'adds all songs of an artist when the request includes only artist' do
      get '/add/songs/artist/adele'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to include("currentPlaylist")
      expect(JSON.parse(last_response.body)["currentPlaylist"].map { |song| song["artist"] }).to all(eq("Adele"))
      expect(JSON.parse(last_response.body)["currentPlaylist"]).to include(
         include("album" => "19"), include("album" => "25"), include("album" => "30"))
   end

   it 'returns not found if the URI is not defined' do
      get '/notexpected'
      expect(last_response.status).to eq(404)
      expect(JSON.parse(last_response.body)).to include('message' => 'Not found')
      expect(last_response.content_type).to eq('application/json')
   end


end
