# GOV.UK PaaS Product Page

This is the source for the PaaS product page at https://www.cloud.service.gov.uk/

It is based on: https://github.com/alphagov/product-page-example

## Running locally

- `bundle install`
- `bower install`
- `bundle exec middleman server`
- `open http://localhost:4567`

## Using Docker

This application supports docker for release scripts.

To make use of it, follow these steps:

1. Build the docker image

    ```
    $ docker build -t paas-product-page .
    ```

    You may also want to install the existing image instead:

    ```
    $ docker pull governmentpaas/paas-product-page
    ```

1. Run the image

    With this command, you'll share the current directory with the docker
    container and connect into it.

    ```
    $ docker run -ti --rm -v $(pwd):/app -w /app -p 127.0.0.1:4567:4567 paas-product-page ash
    ```

1. Run a desired action

    ```
    $ ./release/build
    ```

1. Run a live-reloading server

    ```
    $ bundle exec middleman server
    ```

    You can then view the site on the host machine at http://localhost:4567/

## Deploying changes

This application should not be manually deployed to production. A pipeline
in [alphagov/paas-release-ci][https://github.com/alphagov/paas-release-ci]
will automatically deploy changes to the `master` branch.

You may wish to manually deploy this application to a different
environment in order to test some changes. We've provided a release
script for both `build` and `push` for your convinience.

Check in your changes to master.

```
$ ./release/push
```

Note: you will need the correct PaaS permissions as well as target your 
desired organisation and space.

## Redirection rules

This project adds a custom `nginx.conf` that  supports redirection for a set
of given domains. The domains should be in the `Host` or  X-Forwarded-Host`
(for cloudfront) of the request header.

This is useful for redirecting from an old domain or add a `www` prefix,
like `cloud.service.gov.uk` to `www.cloud.service.gov.uk`.

To change configure it, add the environment variable `REDIRECT_RULES` as follows:

    REDIRECT_RULES=cloud.service.gov.uk:www.cloud.service.gov.uk,government-paas-developer-docs.readthedocs.io:www.cloud.service.gov.uk

You can specify variables from nginx, like `$request_uri`:

    REDIRECT_RULES='government-paas-developer-docs.readthedocs.io:www.cloud.service.gov.uk$request_uri'
