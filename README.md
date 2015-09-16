# docker-symfony-dev

Docker image for Symfony2 website development containing nginx, php-fpm, apc, [composer](https://getcomposer.org/), [xDebug](/app/Resources/doc/docker.md#xdebug) & [blackfire](https://blackfire.io).

## Usage

You can see here an example of a functionnal `docker-compose.yml` containing the app and the MySQL db :

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

Then, go to `http://localhost:13080/`, or use [https://github.com/jderusse/docker-dns-gen](https://github.com/jderusse/docker-dns-gen) and go to `http://app.project.docker`.

## Tools

### xDebug

You can use xDebug with [PhpStorm](https://www.jetbrains.com/phpstorm/) & the [Chrome xDebug extension](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc).

For PhpStorm configuration :

* Add a new *Run/debug configuration* : choose the **PHP remote debug** type
* Ide key : `PHPSTORM`,
* Add a new server, write the client base url check **Use path mapping**, and associate you project root path with `/var/www`

### Blackfire

You can use Blackfire by uncomenting all blackfire references in `docker-compose.yml` and setting the BLACKFIRE_SERVER_TOKEN and BLACKFIRE_SERVER_ID variables.

You can find the values in [Blackfire > Account > My Credentials](https://blackfire.io/account/credentials) or in the [Teams tab](https://blackfire.io/teams)

## Symfony

As you can see in the `default` file, the `app_dev.php` file isn't supported : we are working with environment var.

### Step 1 : Remove the `app_dev.php`

```bash
rm web/app_dev.php
```

### Step 2 : Update the `app.php`

```php
<?php

use Symfony\Component\ClassLoader\ApcClassLoader;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Debug\Debug;

$loader = require_once __DIR__.'/../app/bootstrap.php.cache';

$debug = (bool) getenv('SYMFONY_DEBUG');
$env = getenv('SYMFONY_ENV') ?: 'prod';
$errorReportingLevel = getenv('SYMFONY_HIDE_DEPRECATED') ? E_ALL & ~E_USER_DEPRECATED : null;

if ($debug) {
    Debug::enable($errorReportingLevel);
}

if ('prod' === $env && extension_loaded('apc')) {
    $apcLoader = new ApcClassLoader(sha1(__FILE__), $loader);
    $loader->unregister();
    $apcLoader->register(true);
}

require_once __DIR__.'/../app/AppKernel.php';
//require_once __DIR__.'/../app/AppCache.php';

$kernel = new AppKernel($env, $debug);
$kernel->loadClassCache();
//$kernel = new AppCache($kernel);
// When using the HttpCache, you need to call the method in your front controller instead of relying on the configuration parameter
//Request::enableHttpMethodParameterOverride();

$request = Request::createFromGlobals();
$response = $kernel->handle($request);
$response->send();
$kernel->terminate($request, $response);
```
