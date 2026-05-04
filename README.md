# php-debian

Opinionated, production-ready Docker images for PHP on Debian. Each image bundles **PHP-FPM + Nginx + Supervisor + Composer + ionCube + Redis + supercronic** in a single container, ready to drop a PHP application into `/var/www/html`.

Images are built from the official `php:<version>-fpm-*` bases and published to GitHub Container Registry.

## Available tags

Built and published from [`.github/workflows/ci.yml`](.github/workflows/ci.yml) on every push to `main`.

| Tag | Base image |
| --- | --- |
| `7.4-fpm` | `php:7.4-fpm-bullseye` |
| `8.1-fpm` | `php:8.1-fpm-bookworm` |
| `8.2-fpm` | `php:8.2-fpm-bookworm` |
| `8.3-fpm` | `php:8.3-fpm-bookworm` |
| `8.4-fpm` | `php:8.4-fpm-bookworm` |
| `8.5-fpm` | `php:8.5-fpm-bookworm` |

Pull from GHCR:

```bash
docker pull ghcr.io/itsmattius/php-debian:8.3-fpm
```

## What's inside

- **Web stack** — Nginx (default site at [`.docker/etc/nginx/sites-available/default`](.docker/etc/nginx/sites-available/default)) talking to PHP-FPM over a Unix socket at `/run/php/php-fpm.sock`.
- **PHP extensions** — `bcmath`, `opcache`, `mysqli`, `pdo_mysql`, `gmp`, `intl`, `zip`, `sockets`, `bz2`, `pcntl`, `soap`, `gd`, plus `redis` (PECL) and the **ionCube Loader**.
- **Composer** — installed globally; project-local `vendor/bin` is on `PATH`.
- **Process supervision** — `supervisord` runs `php-fpm`, `nginx`, and a cron worker. See [`.docker/etc/supervisor/conf.d/master.conf`](.docker/etc/supervisor/conf.d/master.conf).
- **Cron** — [supercronic](https://github.com/aptible/supercronic) reads `/etc/crontab`. Default jobs run `/var/www/html/crons/cron.php` and `/var/www/html/crons/pop.php` every 5 minutes — override `/etc/crontab` if your app uses different paths.
- **Logs** — Nginx access/error and supervisor/PHP-FPM output are wired to `stdout`/`stderr` so `docker logs` just works.

## Usage

Mount your app at `/var/www/html` and expose port 80:

```bash
docker run -d \
  --name myapp \
  -p 8080:80 \
  -v "$PWD":/var/www/html \
  ghcr.io/itsmattius/php-debian:8.3-fpm
```

Or with `compose.yaml`:

```yaml
services:
  app:
    image: ghcr.io/itsmattius/php-debian:8.3-fpm
    ports:
      - "8080:80"
    volumes:
      - ./:/var/www/html
```

The Nginx site serves from `/var/www/html` with `index.php` as the front controller (`try_files $uri $uri/ /index.php?$query_string`), so frameworks like Laravel or Symfony work out of the box. `client_max_body_size` is `0` (unlimited) and `fastcgi_read_timeout` is `900s`.

### PHP-FPM tuning

`pm = ondemand`, `pm.max_children = 100`, `pm.max_requests = 500`, `open_basedir` restricted to `/var/www/`, `/tmp/`, `/var/tmp/`, `/dev/urandom`. Edit [`.docker/usr/local/etc/php-fpm.d/www.conf`](.docker/usr/local/etc/php-fpm.d/www.conf) and rebuild to change.

### HTTPS behind a proxy

The Nginx config maps `X-Forwarded-Proto: https` into the `HTTPS` FastCGI param, so PHP sees the correct scheme when running behind a TLS-terminating reverse proxy.

## Customizing

All baked-in config lives under [`.docker/`](.docker/) and is copied into the image during build:

- [`.docker/etc/nginx/sites-available/default`](.docker/etc/nginx/sites-available/default) — Nginx vhost
- [`.docker/etc/supervisor/conf.d/master.conf`](.docker/etc/supervisor/conf.d/master.conf) — supervisord programs
- [`.docker/usr/local/etc/php/php.ini`](.docker/usr/local/etc/php/php.ini) — base php.ini
- [`.docker/usr/local/etc/php/conf.d/opcache.ini`](.docker/usr/local/etc/php/conf.d/opcache.ini) — OPcache settings
- [`.docker/usr/local/etc/php-fpm.d/www.conf`](.docker/usr/local/etc/php-fpm.d/www.conf) — FPM pool
- [`.docker/usr/local/etc/php-fpm.d/zz-docker.conf`](.docker/usr/local/etc/php-fpm.d/zz-docker.conf) — FPM docker overrides

To build locally:

```bash
docker build -f 8.3-fpm.Dockerfile -t php-debian:8.3-fpm .
```

The Dockerfiles use a BuildKit bind mount (`--mount=type=bind,source=.docker,...`), so BuildKit must be enabled (default on modern Docker).

## License

[MIT](LICENSE) © Mehdi Abedi
