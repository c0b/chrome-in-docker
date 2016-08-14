
# google-chrome in docker

*Need to test some latest Chrome version's features?* but hestitant to
upgrade your main browser to unstable? this chrome-in-docker project can help you

## Features

- It downloads a google-chrome Linux version from chrome channels, either
  stable, or beta, or developer version; install and pack into a docker
  container, that can run on anywhere you have docker daemon;
  https://www.chromium.org/getting-involved/dev-channel#TOC-Linux

- It turns google-chrome into a headless browser, can be used together
  with Selenium with chrome webdriver, or with Chrome's native Remote
  Debugging Protocol you can program with
  https://developer.chrome.com/devtools/docs/debugger-protocol
  https://github.com/cyrus-and/chrome-remote-interface
  that makes it a better headless browser than PhantomJS or SlimerJS,
  better programability in my opinion;
  while if need debugging, you have a VNC session to see the actual browser,
  and do whatever you want, or you can even use it as your everyday main browser.

# Usage

You may either just pull my prebuilt docker image at https://hub.docker.com/r/c0b0/chrome-stable/

    $ docker pull c0b0/chrome-stable
    $ docker run -it --rm c0b0/chrome-stable /opt/google/chrome/google-chrome --version
    Google Chrome 52.0.2743.116

Or build it locally with Dockerfile here

    $ docker build -t chrome-stable:20160813 .

Check what Chrome version is builtin, and tag a version:

    $ docker run -it --rm chrome-stable:20160813 /opt/google/chrome/google-chrome --version
    Google Chrome 52.0.2743.116
    $ docker tag chrome-stable:20160813 chrome-stable:52.0.2743.116

The extra `get-latest-chrome.sh` script here is to get latest versions of
Chrome Stable, Beta, or Unstable version, for testing some latest features,
here you may modify the Dockerfile to build a different image with each one,
while, since the beta and unstable versions are changing fast, may be updating
every week or every day, you don't have to rebuild docker images everyday,
with this `get-latest-chrome.sh` and local volume bind, you can run a different
container with the same image; that way, within a relatively longer time range
you don't have to rebuild the base docker image; the reasons of a same base image
can be reused is dependencies of the different channels (stable, beta, or -dev)
are most probably the same, or changing much less often; anyway, if there is
any problem that stable can run but unstable cannot, you may always have a no-cache
rebuild: by `docker build --pull --no-cache ...` to force pull latest ubuntu base
and latest Chrome binary packages.

    $ ./get-latest-chrome.sh
    [... downloading latest Chrome and extracting to ./opt ...]

You may test run it one time first to check what's exact version of each Chrome channel:

    $ docker run -it --rm -v $PWD/opt:/opt:ro chrome:20160813 \
                             /opt/google/chrome-unstable/google-chrome-unstable --version
    Google Chrome 54.0.2824.0 dev

    $ docker run -it --rm -v $PWD/opt:/opt:ro chrome:20160813 \
                             /opt/google/chrome-beta/google-chrome-beta --version
    Google Chrome 53.0.2785.57 beta

    $ docker run -it --rm -v $PWD/opt:/opt:ro chrome:20160813 \
                             /opt/google/chrome/google-chrome --version
    Google Chrome 52.0.2743.116

Then run 3 different containers with the same base docker image:

```console
$ docker run -dt \
             --name Chrome-dev-54.0.2824.0 \
             -h chrome-dev-54.local \
             -v $PWD/opt:/opt:ro \
             -e CHROME=/opt/google/chrome-unstable/google-chrome-unstable \
         chrome:20160813
56417156ffea4a55642cfa59cf5e9758a2be144144b2df39e91aa9265f098b75
$ docker run -dt \
             --name Chrome-beta-53.0.2785.57 \
             -h chrome-beta-53.local \
             -v $PWD/opt:/opt:ro \
             -e CHROME=/opt/google/chrome-beta/google-chrome-beta \
         chrome:20160813
d5b784cbe9ac7d3a52b43c7fb6918b28366c8b939293b10fb9b1808de7b46e2e
$ docker run -dt \
             --name Chrome-stable-52.0.2743.116 \
             -h chrome-beta-52.local \
             -v $PWD/opt:/opt:ro \
             chrome:20160813
35974a5247cf8650da25d03d9f279749ae4cf1e5b0c57349af1d511b8ac99545

$ docker ps -a
CONTAINER ID  IMAGE            COMMAND      CREATED  STATUS  PORTS  NAMES
35974a5247cf  chrome:20160813  "/entry.sh"  ...                     Chrome-stable-52.0.2743.116
d5b784cbe9ac  chrome:20160813  "/entry.sh"  ...                     Chrome-beta-53.0.2785.57
56417156ffea  chrome:20160813  "/entry.sh"  ...                     Chrome-dev-54.0.2824.0
```

To connect the chrome in docker, you may either use port mappings, let it call proper
iptables to set up proper mappings; or use inspect to find out the ip addresses
of each container:

    $ docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' Chrome-dev-54.0.2824.0
    172.18.0.4

That means the chrome browser's Chrome Debugging Protocol can be accessed by `172.18.0.4:9222`

    $ curl -s 172.18.0.4:9222/json/version
    {
       "Browser": "Chrome/54.0.2824.0",
       "Protocol-Version": "1.1",
       "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2824.0 Safari/537.36",
       "WebKit-Version": "537.36 (@facabd3224aecbcab4bea9daadad31c67488d78c)"
    }

Or, if you use docker port mapping, like:

```console
         #  this one is not using any local volume binding on /opt, so it's using the builtin Chrome at build time,
$ docker run -dt \
             --name Chrome-stable-builtin-52.0.2743.116 \
             -h chrome-stable-52.local \
             -p 9222:9222 \
         chrome:20160813
e9a3738f2d642e5d1a4dd895750d1a09ddece3dd187c82309ade99e1b4123027
$ docker ps -a
CONTAINER ID  IMAGE            COMMAND      CREATED        STATUS         PORTS                     NAMES
e9a3738f2d64  chrome:20160813  "/entry.sh"  3 seconds ago  Up 3 seconds   0.0.0.0:9222->9222/tcp   Chrome-stable-builtin-52.0.2743.116

        # by inspect we know we can access this container by 172.18.0.2:9222
$ docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' Chrome-stable-builtin-52.0.2743.116
172.18.0.2
$ curl -s 172.18.0.2:9222/json/version
{
   "Browser": "Chrome/52.0.2743.116",
   "Protocol-Version": "1.1",
   "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",
   "WebKit-Version": "537.36 (@9115ecad1cae66fd5fe52bd9120af643384fd6f3)"
}
        # by above port mapping, this container can also be accessed by 0.0.0.0:9222; if it's from localhost Linux, 
$ curl -s localhost:9222/json/version
{
   "Browser": "Chrome/52.0.2743.116",
   "Protocol-Version": "1.1",
   "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",
   "WebKit-Version": "537.36 (@9115ecad1cae66fd5fe52bd9120af643384fd6f3)"
}
```

You may try https://github.com/cyrus-and/chrome-har-capturer with more har capturing commands
like `chrome-har-capturer -t 172.18.0.2 urls...`

## Debugging

VNC session listens default on the container's 5900 port, if you figured out the container's
IP address (by above inspect command), an VNC session can be opened by your favorite
VNC client connect to this ip address, or you may use another `-p localport:5900`
to set up another port forwarding to be able to use it from a 3rd computer.

## Env variables to customize

1. the default VNC password is `hola`; you may pass additional env var to docker run
   by `-e VNC_PASSWORD=xxx` to change to use a different VNC password;
2. the default CHROME is `/opt/google/chrome/google-chrome`, if you use local
   volume bind to have different chrome versions, you may pass additional env var
   by `-e CHROME=/path/to/chrome or chromium`

# Design

## Docker Image Build Time

1. The Dockerfile defined process of where as start, it's starting from latest

2. Ubuntu as base image, then install VNC and some network utilties like curl and socat,
xvfb, x11vnc as Graphic layer for Chrome graphical output, xterm as debugging term window
supervisor as processes manager, sudo also for debugging, not technically required.

3. Then add Google-Chrome's apt source and install google-chrome-stable version,
and it will handle all runtime dependencies by Chrome;
This static version will be packed as part of the docker image, when you're not
using local volume bind, this version will be used. It depends how often do you
rebuild, but with above `./get-latest-chrome.sh` script, you don't have to rebuild
very often.

3. Then add a regular user at 1000:100 for improved security and run all services
under this regular user; sudo can be used for debugging.
Copying supervisord.conf as definition of process structure; and entry.sh as
container entrypoint.

## Container Spawn
At container spawn time (`docker run ...`), it starts from the entrypoint `entry.sh`
there it handles default VNC password `hola`, and check CHROME environment,
set it default to the stable version `/opt/google/chrome/google-chrome`;

Then it exec to supervisord to spawn more processes defined in `supervisord.conf`

## Process Management

Supervisord is the process manager, it spawns 4 processes:

1. Xvfb ... as X server
2. x11vnc ... as VNC on top of X Server
3. fluxbox as window manager, this is technically not required,
   any X11 application can directly run on X server, but with a window
   manager, it's easier for debugging, when need to move window, resize,
   maximize, and minimize, etc.
4. xterm, same for debugging
5. start chrome from CHROME environment variable, with `--remote-debugging-port=19222`
   to enable Remote Debugging Protocol
4. socat, as a forwarding channel, chrome can only listen on local loopback
   interface (127.0.0.1); hence not accepting any request from outside
   so a tcp forwarding tool like socat is necessary here.

Supervisord will respawn any managed processes if it crashed.

Ideally here should define dependencies between the processes, but due to
https://github.com/Supervisor/supervisor/issues/122 it lacks such feature.

# Some further improvements

- [ ] Chromium nightly https://download-chromium.appspot.com/
- [ ] VNC in browser, see https://github.com/fcwu/docker-ubuntu-vnc-desktop
      have an openbox version, or lxde, an lightweight also full featured
      Ubuntu desktop
- [ ] setup iptables instead of socat
- [ ] find replacement of supervisord, need a lightweight mananger also has
      dependencies management. But sysvinit, upstart, or systemd is too heavy.