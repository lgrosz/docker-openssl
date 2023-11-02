# General a docker container with an OpenSSL install in it

# Images

Dockerfile contains an install of OpenSSL, built from scratch.

The install is located at `C:\Program Files\OpenSSL`

# Build image

```
$ docker build .
```

# Pull image

```
$ docker pull lgrosz/openssl:1.1.1w
```
