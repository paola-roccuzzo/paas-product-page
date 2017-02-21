# GOV.UK PaaS Product Page

This is the source for the PaaS product page at https://www.cloud.service.gov.uk/

It is based on: https://github.com/alphagov/product-page-example

## Running locally

- `bundle install`
- `bower install`
- `bundle exec middleman server`
- `open http://localhost:4567`

## Deploying changes

Check in your changes to master.

 * Deploy to prod: Run `./deploy`
 * Deploy for testing: `PRODUCT_ORG_NAME=paas-demo PRODUCT_SPACE_NAME=sandbox PRODUCT_APP_NAME=test-govuk-paas ./deploy`

Note: you will need the correct PaaS permissions.

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
