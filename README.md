# docker-symfony-dev

Docker image for Symfony2 website development

## Usage

`docker-compose.yml`

```yml
app:
  image: mroca/symfony-dev
  links:
    - mysql:mysql.project.docker
    - blackfire:blackfire
  ports:
    - "13080:80"
  volumes_from:
    - volumecache
  volumes:
    - ./:/var/www
    - /var/www/app/cache
    - /var/www/app/logs
  environment:
    DOMAIN_NAME: app.project.docker
    SYMFONY_ENV: dev
    SYMFONY_DEBUG: 1
    SYMFONY_HIDE_DEPRECATED: true

mysql:
  image: mysql:5.6
  ports:
    - "13036:3306"
  environment:
    DOMAIN_NAME: mysql.project.docker
    MYSQL_DATABASE: project
    MYSQL_ROOT_PASSWORD: root

volumecache:
  image: busybox
  volumes:
    - ~/.composer:/root/.composer
    # - /var/www/vendor # For mac users

# Comment in order to use blackfire
blackfire:
  image: busybox
  command: tail -f /dev/null

## Complete credentials and uncomment to use blackfire
#blackfire:
#  image: blackfire/blackfire
#  environment:
#    BLACKFIRE_LOG_LEVEL: 4
#    BLACKFIRE_SERVER_ID: null
#    BLACKFIRE_SERVER_TOKEN: null
```

## Docker

Docker (https://docs.docker.com/) containers containing the app (nginx, php-fpm, apc, xDebug, Blackfire & composer) and the db (MySQL) are available for the dev.

### Build

```bash
docker-compose build
```

### Run

```bash
# With logs output
docker-compose up

# In background
docker-compose up -d && docker-compose logs
```

Then, go to [http://localhost:13080/](http://localhost:13080/),
or use [https://github.com/jderusse/docker-dns-gen](https://github.com/jderusse/docker-dns-gen)
and go to [http://app.project.docker](http://app.project.docker).

The php docker image contains composer, [xDebug](/app/Resources/doc/docker.md#xdebug) & [blackfire](https://blackfire.io).

#### xDebug

You can use xDebug with PhpStorm & the [Chrome xDebug extension](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc).

For PhpStorm configuration :

* Add a new *Run/debug configuration* : choose the **PHP remote debug** type
* Ide key : `PHPSTORM`,
* Add a new server, write the client base url check **Use path mapping**, and associate you project root path with `/var/www`

#### Blackfire

You can use Blackfire by uncomenting all blackfire references in `docker-compose.yml` and setting the BLACKFIRE_SERVER_TOKEN and BLACKFIRE_SERVER_ID variables.

You can find the values in [Blackfire > Account > My Credentials](https://blackfire.io/account/credentials) or in the [Teams tab](https://blackfire.io/teams)
