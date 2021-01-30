require 'mp3info'

def make_test_audio_file(file_info)
   system("ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 15 -q:a 9 -acodec libmp3lame \"#{file_info[:file_name]}\"")

   Mp3Info.open(file_info[:file_name]) do |file|
      file.tag.artist = file_info[:artist]
      file.tag.title = file_info[:title]
      file.tag.album = file_info[:album]
      file.tag.genre_s = file_info[:genre]
   end
end
