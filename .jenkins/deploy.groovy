pipeline {
  agent none

  options {
    disableConcurrentBuilds()
  }

  stages {
    stage('Fetch Code') {
      agent any
      steps {
        checkout scm
        script {
          env.RUBY_VERSION = readFile('.ruby-version').trim()
          docker.build(
            "umts/kamal:${env.RUBY_VERSION}",
            "--file ./.jenkins/kamal.dockerfile --build-arg RUBY_VERSION=${env.RUBY_VERSION} ."
          )
        }
      }
    }

    stage('Deploy') {
      agent {
        docker {
          image "umts/kamal:${env.RUBY_VERSION}"
          args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
          reuseNode true
        }
      }
      steps {
        sh 'bundle install'
        sh 'docker build --tag gtfs_cache --build-arg RUBY_VERSION="${RUBY_VERSION}" .'
        withCredentials([sshUserPrivateKey(credentialsId: 'kamal-ssh',
                                           usernameVariable: 'KAMAL_SSH_USER',
                                           keyFileVariable: 'KAMAL_SSH_KEY_PATH')]) {
          sh 'echo "$KAMAL_SSH_USER"'
          sh 'bundle exec kamal details'
        }
      }
    }
  }
}
