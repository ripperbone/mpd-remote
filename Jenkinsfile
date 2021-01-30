pipeline {
   agent {
      docker { 
         image 'mpd-remote-buildenv'
         reuseNode true
         args '-u root'
      }
   }
   
   stages {
      stage('setup') {
         steps {
            sh """
               echo "Starting MPD"
               service mpd start
            """
         }
      }
      stage('rspec') {
         steps {
            sh """
               bundle config set --local path vendor/bundle
               gem env
               bundle install
               bundle exec rspec
            """
         }
      }
   }
}
