# pipeline stats

1. Start jaeger all in one docker image:

```
$ docker pull jaegertracing/all-in-one:1.7
$ docker run -p 6831:6831/udp -p 6832:6832/udp -p 16686:16686 jaegertracing/all-in-one:1.7 --log-level=debug
```

2. Send traces to jaeger:

```bash
for file in traces/puppet-agent-*.yaml; do echo $file; ruby tracer.rb $file; done
```

3. Browse to `http://localhost:16686`
