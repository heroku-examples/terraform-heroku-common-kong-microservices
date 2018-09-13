# Heroku microservices with a unified gateway using Terraform

🔬 This is a community proof-of-concept, [MIT license](LICENSE), provided "as is", without warranty of any kind.

![Diagram: Terraform a complete multi-app
architecture with Heroku Private Spaces, 
a Kong gateway, & DNSimple](doc/terraform-heroku-kong-microservices-v01.png)

## Architecture

A Heroku [Private Space](https://devcenter.heroku.com/articles/private-spaces) provides a container for [internally routed apps](https://devcenter.heroku.com/articles/internal-routing) that are only accessible within its private network.

Each microservice (internal app) is exposed to the internet through a Kong [service](https://docs.konghq.com/0.14.x/admin-api/#service-object) & [route](https://docs.konghq.com/0.14.x/admin-api/#route-object) with a [custom domain name](https://devcenter.heroku.com/articles/custom-domains), secured via [automated certificate management](https://devcenter.heroku.com/articles/automated-certificate-management).

A single [Terraform config](https://www.terraform.io/docs/configuration/index.html) embodies the complete system, enabling high-level collaboration, repeatability, test-ability, and change management.

The primary components are:

* [Heroku](https://www.heroku.com/home) provides the primatives: Private Spaces, Apps, and Add-ons
* [Kong CE](https://konghq.com/kong-community-edition/) provides a high-performance HTTP proxy/gateway with [plugins](https://konghq.com/plugins/) supporting access control, flow control, logging, circuit-breaking, and more including custom plugins
* [Terraform](https://terraform.io) provides declarative, unified systems configuration with support for over 120 providers, a human-friendly configuration as code format, and a deterministic provisioning engine
* [DNSimple](https://dnsimple.com) provides API-driven domain name configuration.

## Requirements

* [Heroku](https://www.heroku.com/home)
  * install [command-line tools (CLI)](https://toolbelt.heroku.com)
  * [a free account](https://signup.heroku.com)
* [DNSimple](https://dnsimple.com)
  * at least a personal account ($5/month)
  * a domain name added to that account
* install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* install [git-lfs](https://git-lfs.github.com) (efficiently supports checking Heroku app slugs into version control)
* install [Terraform](https://terraform.io)

## Usage

Ensure the [requirements](#user-content-requirements) are met, then,

1. Clone this repo:

    ```bash
    git clone git@github.com:mars/terraform-heroku-kong-microservices.git
    cd terraform-heroku-kong-microservices/
    ```
2. Install [terraform-provider-kong 1.7.0](https://github.com/kevholditch/terraform-provider-kong/releases/tag/v1.7.0)
    * download the `.zip` asset for your computer's architecture
    * unzip it into `terraform.d/plugins/$ARCH/`
    * where `$ARCH` is the computer's architecture, like `darwin_amd64`
3. Set Heroku API key
    1. `heroku authorizations:create -d terraform-heroku-kong-microservices`
    2. `export HEROKU_API_KEY=<"Token" value from the authorization>`
4. Setup DNS
    1. locate the account ID & API token ([help](https://support.dnsimple.com/articles/api-access-token/))
    2. `export DNSIMPLE_ACCOUNT=xxxxx DNSIMPLE_TOKEN=yyyyy`
5. `terraform init`
6. Then, apply the config with your own top-level config values:

    ```bash
    terraform apply \
      -var name=kong-micro \
      -var dns_zone=example.com \
      -var heroku_enterprise_team=example-team
    ```
