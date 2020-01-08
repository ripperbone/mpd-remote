
require_relative '../app'
require 'rspec'
require 'rack/test'


RSpec.describe 'MPD web interface' do
   include Rack::Test::Methods

   def app
      App
   end

   it 'returns the currently playing song details' do
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

   it 'returns not found if the URI is not defined' do
      get '/notexpected'
      expect(last_response.status).to be(404)
      expect(JSON.parse(last_response.body)).to include('message' => 'Not found')
      expect(last_response.content_type).to eq('application/json')
   end


end
