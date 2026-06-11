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
            "--build-arg RUBY_VERSION=${env.RUBY_VERSION} ./.jenkins/kamal.dockerfile"
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
        sh 'bundle exec kamal help'
        sh "docker build --tag gtfs_cache --build-arg RUBY_VERSION=${env.RUBY_VERSION} ."
      }
    }
  }
}
