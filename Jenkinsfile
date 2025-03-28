pipeline {
   agent {
      dockerfile true
   }
   
   stages {
      stage('rspec') {
         steps {
            sh """
               whoami
               sudo -u mpd /usr/bin/mpd
               bundle config set --local path vendor/bundle
               gem env
               bundle install
               bundle exec rspec --format progress --format html --out rspec_results.html
            """
         }
      }
   }
}
