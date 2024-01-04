pipeline {
  agent any
  tools { 
     jdk 'java21slave' 
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '1'))
  }
  environment {
    LOGSTASH = 'nuc:5044'
  }  
  stages {
    stage('Git') {
      steps {
        git(url: 'https://github.com/wlanboy/CloudConfigPropertyGenerator.git', branch: 'master')
      }
    }
    stage('Build') {
      steps {
        sh 'mvn clean package'
      }
    }


  }
}
