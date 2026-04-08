pipeline {
   agent {
      dockerfile {
         additionalBuildArgs '--build-arg JENKINS_UID=110'
      }
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
               bundle exec rspec --format progress --format html --out reports/rspec_results.html
            """
         }
      }
   }
   post {
      always {
         publishHTML(target: [
            allowMissing: true,
            alwaysLinkToLastBuild: true,
            keepAll: false,
            reportDir: 'reports',
            reportFiles: 'rspec_results.html',
            reportName: 'Reports'])

         emailext(to: '$DEFAULT_RECIPIENTS', subject: "${env.JOB_NAME} build ${env.BUILD_NUMBER} finished - ${currentBuild.currentResult}", body: '''<pre>\${BUILD_LOG, maxLines=500, escapeHtml=false}</pre>''', mimeType: 'text/html')
      }
   }
}
