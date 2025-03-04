# Lua benchmark: OpenResty vs NGINX+WSAPI

## Installation

Here are instructions to install [OpenResty](https://openresty.org/en/installation.html) and [LuaRocks](https://luarocks.org/#quick-start).

Next install what we need for our specific benchmarks. These instructions work on Ubuntu (otherwise see troubleshooting note on missing packages below):

```shell
apt install apache2-utils  # supplies ab, the apache benchmark tool
apt install libfcgi-dev    # supplies fcgi_stdio.h
sudo luarocks install wsapi-fcgi
apt install lua5.1 liblua5.1-dev      # required to build uWSGI with lua5.1 support
apt install lua5.4 liblua5.4-dev      # required to build uWSGI with lua5.4 support
apt install luajit libluajit-5.1-dev  # required to build uWSGI with luajit support
apt install apache2  # needed for benchmark with apache and Lua
```

Start your nginx and fcgi servers:

```shell
make start
```

Test that nginx is working:

```shell
$ make test
Testing resty server
curl -fsS "http://localhost:8081/multiply?a=2&b=3"
<html><body><p>Hello NGINX-Lua!</p><p>PATH=/multiply</p><p>RESULT: 2*3=6</p></body></html>

Testing fcgi server
curl -fsS "http://localhost:8082/multiply?a=2&b=3"
<html><body><p>Hello WSAPI!</p><p>PATH=/multiply</p><p>RESULT: 2*3=6</p></body></html>

...
```

Run the benchmarks:

```shell
make summary  # or try make benchmarks for more info
make stop  # when you're done testing, stop the servers make started
```

Peruse the `Makefile` for other useful make targets if you want to test specific things.

## Results

The benchmark results on a quad-core i7-8565 @1.8GHz are as follows, where 8081 is port serving OpenResty's Lua and 8082 is PUC Lua via FastCGI:

```shell
$ make summary
Benchmarking openresty LuaJIT
ab -k -c1000 -n50000 -S "http://localhost:8081/multiply?a=2&b=3"
Time taken for tests:   0.415 seconds
 
Benchmarking apache mod-lua
ab -k -c10 -n50000 -S "http://localhost:8080/multiply?a=2&b=3"
Time taken for tests:   0.966 seconds
 
Benchmarking FastCGI Lua 5.4
ab -k -c10 -n50000 -S "http://localhost:8082/multiply?a=2&b=3"
Time taken for tests:   2.720 seconds
 
Benchmarking uwsgi/lua5.1
ab -k -c100 -n50000 -S "http://localhost:8083/multiply?a=2&b=3"
Time taken for tests:   2.536 seconds
 
Benchmarking uwsgi/lua5.4
ab -k -c100 -n50000 -S "http://localhost:8083/multiply?a=2&b=3"
Time taken for tests:   2.506 seconds
 
Benchmarking uwsgi/luajit
ab -k -c100 -n50000 -S "http://localhost:8083/multiply?a=2&b=3"
Time taken for tests:   2.573 seconds
```

In short, OpenResty's Lua solution is our baseline. Apache with PUC Lua takes **2× as long**. FastCGI takes **6.5× as long** and uWSGI's WSAPI prototcol takes **6× as long**. Since our Lua program is so small and simple, it makes no difference whether we use Lua 5.1, Lua 5.4 or LuaJIT.

The overheads we're really testing here have to do with the protocol being used to serialize commands sent to Lua:

- **1×**: OpenResty - no serialization protocol - fastest by far
- **2×**: Apache – no serialization protocol
- **6×**: WSAPI protocol
- **6.5×**: FastCGI protocol

**Note:** It's possible that there is a way to double the speed of my FastCGI and WSAPI benchmarks, because my CPU load is only about 50% of each core (using htop) when I run those tests, whereas OpenResty and Apache tests use 100% of every core. I don't know why NGINX doesn't parallel those up sufficiently to use 100% CPU. There may be a better server config, but I've tried various ones and I can't find it.

## Troubleshooting

### Deprecation warning

Please note that although uWSGI is used as a benchmark comparison point, it is already in maintenance mode and building it already has deprecation warnings for use of old ssl and python distutils functions. Because of this, it requires python < 3.12 and it is not clear what version of libssl-dev will drop support.

### Missing packages

If your OS does have the specified Lua packages, you may need to build them from source. In that case, you will need to change the Makefile to specify locations to them. See [uWSGI notes on using Lua](https://uwsgi-docs.readthedocs.io/en/latest/Lua.html#:~:text=If%20you%20do%20not%20want%20to%20rely%20on%20the%20pkg%2Dconfig%20tool).

### Too many open files

If you get this error when you run `make benchmark` then the benchmarking is trying to make more simultaneous requests than your user allows. Check the number of requests your user is allowed as follows:

```shell
$ ulimit -Hn
1048576
$ ulimit -Sn
1024
```

These numbers should be significantly greater than the `-c<connections>` parameter in the `ab` command run by `make benchmark`. If not, see how to increase your open file limit [here](https://www.cyberciti.biz/faq/linux-unix-nginx-too-many-open-files/) or [here for Ubuntu](https://manage.accuwebhosting.com/knowledgebase/3334/How-to-Increase-Open-Files-Limit-in-Ubuntu.html).

