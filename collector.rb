require 'jenkins_api_client'
require 'pp'
require 'json'

config = { log_level: Logger::WARN }
config.merge!(YAML.load_file(File.expand_path("~/.jenkins_api_client/login.yml", __FILE__)))
client = JenkinsApi::Client.new(config)

def find_upstream_build(project, build_details)
  actions = build_details["actions"]

  unless actions
    puts "WARNING #{build_details['fullDisplayName']} doesn't have any actions"
    return []
  end

  actions.each do |action|
    if action["_class"] == "hudson.model.CauseAction"
      action["causes"].each do |cause|
        if cause["_class"] == "hudson.model.Cause$UpstreamCause"
          return [cause["upstreamProject"], cause["upstreamBuild"]]
        end
      end
    end
  end

  return []
end

def find_prior_build(project, build_details, number)
  actions = build_details["actions"]
  restarted = actions.find do |action|
    if action["_class"] == "hudson.model.CauseAction"
      action["causes"].each do |cause|
        if action["_class"] == "hudson.model.Cause$UserCause"
          puts "INFO job was manually started by #{action['userName']}"
          true
        end
      end
    end
  end

  if restarted
    # find first strictly before the current one
    build = project["builds"].find { |b| b["number"] < number}
    build ? build['number'] : nil
  else
    puts "WARN couldn't find prior build"
    nil
  end

  # if there isn't an upstream job, then check to see if a user matrix reloaded
  # the job, and if so, look for the previous
    # if action["_class"] == "hudson.model.Cause$UserCause"
    #   # NOTE if cause is "hudson.model.Cause$UserCause" but it's not the init job,
    #   # then someone started the pipeline in the middle instead of matrix reloading,
    #   # and we probably need to search an earlier "number" for this job and look for
    #   # a matching SHA. But the previous job was probably "result": "ABORTED", so find
    #   # the previous job whose result is "SUCCESS" with the same SHA, if any.
    #   puts "WARNING build #{build_details['fullDisplayName']}} was started by a user, but isn't the init job"
    # end
end

def build_metrics(name, number, build_details, parent:)
  metrics = {}

  metrics = {}
  metrics[:start] = build_details["timestamp"] # milliseconds since epoch

  actions = build_details["actions"] || []
  action = actions.find do |act|
    act["_class"] == "jenkins.metrics.impl.TimeInQueueAction"
  end

  # Metrics
  #
  # |--------------------- total --------------------------|
  # |-------------queuing-----------------|---executing----|
  # |--blocked--|--waiting--|--buildable--|

  if action
    # See https://github.com/jenkinsci/metrics-plugin/blob/master/src/main/java/jenkins/metrics/impl/TimeInQueueAction.java
    # wall time from when it left the queue until from scheduled to completion
    metrics[:executing] = action["executingTimeMillis"]

    # time spent in the queue because they were blocked.
    metrics[:blocked] = action["blockedTimeMillis"]

    # time spent in the queue waiting before it could be considered for execution.
    metrics[:waiting] = action["waitingTimeMillis"]

    # time spent in the queue in a buildable state.
    metrics[:buildable] = action["buildableTimeMillis"
                                ]
    # total time spent queuing
    metrics[:queuing] = metrics[:blocked] + metrics[:waiting] + metrics[:buildable] # milliseconds

    # wall time from when it entered the queue until it was finished.
    metrics[:total] = metrics[:queuing] + metrics[:executing] # milliseconds
  end

  metrics[:stop] = metrics[:start] + metrics[:total]

  times = [metrics[:queuing], metrics[:executing], metrics[:total]]
  times.map! { |tm| to_human(tm) }
  # name can contain '%'
  puts "Queried #{name}/#{number}: " + ("queued=%s, building=%s, total=%s" % times)

  { name: name, number: number, metrics: metrics, parent: parent }
end

def collect_metrics(client, name, number, parent:)
  results = []

  loop do
    # get metrics for a build
    build_details = client.job.get_build_details(name, number)
    if build_details
      results << build_metrics(name, number, build_details, parent: parent)
    else
      raise "Build #{name}/#{number} not found"
    end

    if build_details['_class'] == "hudson.matrix.MatrixBuild"
      build_details['runs'].each do |run|
        if md = run["url"].match(/.*\/(.*)\/(.*)\/(\d+)/)
          run_name = md.captures[0]
          run_axes = md.captures[1]
          run_number = md.captures[2]
#          puts "Collecting #{run_name}/#{run_axes}/#{run_number}"
          results.concat(collect_metrics(client, URI.unescape("#{run_name}/#{run_axes}"), run_number, parent: name))
        end
      end
    end

    # The pipeline init job doesn't have an upstream project
    upstream_projects = client.job.get_upstream_projects(name)
    break if upstream_projects.nil? || upstream_projects.empty?

    # try to find the build for one of our upstream projects
    project = client.job.list_details(name)

    loop do
      # is there an upstream build?
      upstream_name, upstream_number = find_upstream_build(project, build_details)
      if upstream_name
        name = upstream_name
        number = upstream_number
        break
      end

      # find previous build for this project
      prior_number = find_prior_build(project, build_details, number)
      return results unless prior_number

      # REMIND: need to make sure prior build was for the same SHA!

      # get previous build details, and retry

      number = prior_number
      build_details = client.job.get_build_details(name, number)
    end
  end

  results
end

def to_human(tm)
  ms = tm % 1000
  sec = (tm / 1000) % 60
  min = (tm / (1000*60)) % 60
  hrs = (tm / (1000*60*60)) % 24

  if hrs > 0
    "%d hr %d min %d secs" % [hrs, min, sec]
  elsif min > 0
    "%d min %d secs" % [min, sec]
  elsif sec > 0
    "%d secs" % sec
  else
    "%d msecs" % ms
  end
end

#pipelines = client.job.list('^platform_puppet-agent_puppet-agent-suite-init_daily-(master|.*x)')

#pipeline = 'platform_puppet-agent_puppet-agent-vanagon-mergeup_daily-5.5.x'
pipeline = 'platform_puppet-agent_puppet-agent-vanagon-mergeup_daily-master'
pipelines = client.job.list("^#{Regexp.escape(pipeline)}")
pipelines.each do |name|
  total = 0

  details = client.job.list_details(name)
  number = ENV['BUILD_NUMBER']
  unless number
    build = details["lastSuccessfulBuild"]
    raise "Job #{name} has never succeeded" unless build
    number = build["number"]
  end

  # Import reverse metrics
  build_results = collect_metrics(client, name, number, parent: nil).reverse
  build_results.each do |build_result|
    total += build_result[:metrics][:total]
  end

  puts "Pipeline #{name} took #{to_human(total)}"
  puts ""

  results = { name: pipeline, start: build_results.first[:metrics][:start], stop: build_results.last[:metrics][:stop], total: total, results: build_results }
  File.write("#{pipeline}.yaml", YAML.dump(results))
end


