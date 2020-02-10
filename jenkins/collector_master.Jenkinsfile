#!/usr/bin/env groovy
@Library('puppet_jenkins_shared_libraries') _

import com.puppet.jenkinsSharedLibraries.BundleInstall
import com.puppet.jenkinsSharedLibraries.BundleExec

String bundleInstall(String rubyVersion) {
  def bundle_install = new BundleInstall(rubyVersion)
  return bundle_install.bundleInstall
}

String bundleExec(String rubyVersion, String command) {
  def bundle_exec = new BundleExec(rubyVersion, command)
  return bundle_exec.bundleExec
}

boolean gitChangesFound() {
  def statusCode = sh(
    returnStatus: true,
    script: 'git diff-index --quiet HEAD'
  )
  return statusCode == 1
}

pipeline {
  agent { label 'worker' }

  environment {
    GEM_SOURCE='https://artifactory.delivery.puppetlabs.net/artifactory/api/gems/rubygems/'
    RUBY_VERSION='2.5.1'
    PIPELINE_BRANCH='dt_job_01'
    GIT_CHANGED_FILES='0' // will be overriden
    BRANCH='master'
  }

  // parameters {
  //   choice(
  //     name: 'BRANCH',
  //     choices: ['master', '6.4.x', '5.5.x'],
  //     description: 'puppet-agent branch to collect spans from'
  //   )
  // }

  stages {
    stage('bundle install') {
      steps {
        // git branch: "${env.PIPELINE_BRANCH}",
        //     url: 'git@github.com:kevpl/pipeline_stats.git'
        sh bundleInstall(env.RUBY_VERSION)
      }
    }
    stage('collect traces') {
      environment {
        // BRANCH="${params.BRANCH}"
        PIPELINE_STATS_LOGIN_FILE=credentials('jenkins_api_client-login')
      }
      steps {
        sh bundleExec(env.RUBY_VERSION, 'collector')
      }
    }
    // stage('checking for git file changes') {
    //   environment {
    //     GIT_CHANGED_FILES = """${sh(
    //       returnStatus: true,
    //       script: 'git diff-index --quiet HEAD'
    //     )}"""
    //   }
    //   steps {
    //     echo "environment set value for GIT_CHANGED_FILES: '${env.GIT_CHANGED_FILES}'"
    //     if (gitChangesFound()) {
    //       echo "gitChangesFound: FOUND"
    //     } else {
    //       echo "gitChangesFound: NOT NOT NOT"
    //     }
    //   }
    // }
    // stage('next stage git file change check') {
    //   steps {
    //     echo "next stage check, same value: '${env.GIT_CHANGED_FILES}'"
    //     echo "pwd: ${pwd()}"
    //     deleteDir()
    //   }
    // }
    
    stage('commit new traces to project') {
      // when { environment name: 'GIT_CHANGED_FILES', value: '1' }
      steps {
        sh 'git status'
        sh 'git add build_traces'
        sh "git commit -m 'add new puppet-agent-${env.BRANCH} traces'"
        sh "git push origin ${env.PIPELINE_BRANCH}"
      }
    }
  }
  // post {
  //   cleanup {
  //     deleteDir
  //   }
  // }
}