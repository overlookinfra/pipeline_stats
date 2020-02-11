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

pipeline {
  agent { label 'worker' }
  triggers {
    // this timing needs to not overlap with any of the other jobs in this folder
    // because if one job commits traces while another is running, the commit & push
    // step won't work since we're not at the HEAD of the branch
    //
    // ref: https://jenkins.io/doc/book/pipeline/syntax/#cron-syntax
    //
    // this cron statement specifies a run between 6:00 & 8:59am Tuesdays & Saturdays
    cron('H H(6-8) * * 2,6')
  }

  environment {
    GEM_SOURCE='https://artifactory.delivery.puppetlabs.net/artifactory/api/gems/rubygems/'
    RUBY_VERSION='2.5.1'
    // also used in git_commit.sh to know where to push new build traces
    PIPELINE_STATS_BRANCH='master'
    BRANCH='5.5.x'
  }

  stages {
    stage('bundle install') {
      steps {
        // typical git checkout step gets the commit at HEAD
        //   of the branch. That won't work for us, as we want to
        //   commit back to the branch. So we checkout manually:
        git branch: "${env.PIPELINE_STATS_BRANCH}",
            url: 'git@github.com:puppetlabs/pipeline_stats.git'
        sh bundleInstall(env.RUBY_VERSION)
      }
    }
    stage('collect traces') {
      environment {
        // credentials defined as jenkins_api_client's login.yml file
        //   on jenkins-pipeline, these are kept here:
        //   https://cinext-jenkinsmaster-pipeline-prod-1.delivery.puppetlabs.net/credentials/store/system/domain/_/credential/jenkins_api_client-login/
        //   an example of the config file format is in this repo: /config/login.yml
        PIPELINE_STATS_LOGIN_FILE=credentials('jenkins_api_client-login')
      }
      steps {
        sh bundleExec(env.RUBY_VERSION, 'collector')
      }
    }
    stage('commit new traces to project') {
      steps {
        sh 'jenkins/git_commit.sh'
      }
    }
  }
}
