# pipeline stats

## Publishing Traces

1. Start jaeger all in one docker image:

```
$ docker pull jaegertracing/all-in-one:1.7
$ docker run -p 6831:6831/udp -p 6832:6832/udp -p 16686:16686 jaegertracing/all-in-one:1.7 --log-level=debug
```

2. Send traces to jaeger:

```bash
$ bundle install
$ bundle exec rake publish
```

3. Browse to `http://localhost:16686`

## Trace Collection

To collect traces from the last run of a puppet-agent pipeline:

```
$ BRANCH=master bundle exec collector
```

Or specify a specific build number of the `Promote to PE` job:

```
$ BUILD_NUMBER=274 BRANCH=master bundle exec collector
```

### Results

The collector will generate a results file containing metadata and timing information for each job in the pipeline. For example:

```yaml
---
:name: puppet-agent-5.5.x
:sha: 2915296c864d120e5805fb1f4afec6c99a777193
:start: 1568271663277
:stop: 1568299696273
:total: 443130046
:results:
- :name: suite-init
  :number: 311
  :metrics:
    :start: 1568271663277
    :executing: 12244
    :blocked: 0
    :waiting: 4291
    :buildable: 57732
    :queuing: 62023
    :total: 74267
    :stop: 1568271737544
  :parent: 

```

The file contains the puppet-agent branch and SHA, the results for each job in the pipeline,
and the detailed timing information for each job.

### Metrics

The collected metrics are based on the states described in [Jenkins Build Queue](https://javadoc.jenkins-ci.org/hudson/model/Queue.html).

* waiting - how long the job was waiting in the queue before it could be considered for execution. There can be a non-zero amount of time between the time the job is added to the queue and when the [Jenkins Queue Task Dispatcher](https://javadoc.jenkins-ci.org/hudson/model/queue/QueueTaskDispatcher.html) evaluates the job.
* blocked - how long the job was blocked for any reason. Could be due to waiting for ABS resources, upstream/downstream build in progress, etc.
* buildable - how long the job was waiting for an executor to run, such as a static jenkins runner, mesos agent, etc
* queueing - sum of waiting, blocked, buildable
* executing - how long the job ran for
* total - sum of queuing and executing
* start/stop - start and stop times in *seconds* UTC

## Issues

 - [ ] Use [jenkins tree query parameter](https://www.cloudbees.com/blog/taming-jenkins-json-api-depth-and-tree)
 - [ ] Missing span for the [failed MatrixBuild](https://github.com/jenkinsci/matrix-project-plugin/blob/master/src/main/java/hudson/matrix/MatrixBuild.java)
 - [ ] Tag spans (SHA, platform, branch, reloaded?)
 - [ ] Collect spans for blocked, waiting, buildable
