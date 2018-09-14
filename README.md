# Heroku microservices with a unified gateway using Terraform

A Heroku [Private Space](https://devcenter.heroku.com/articles/private-spaces) provides a container for [internally routed apps](https://devcenter.heroku.com/articles/internal-routing) that are only accessible within its private network.

Each microservice (internal app) is exposed to the internet through a Kong [service](https://docs.konghq.com/0.14.x/admin-api/#service-object) & [route](https://docs.konghq.com/0.14.x/admin-api/#route-object) with a [custom domain name](https://devcenter.heroku.com/articles/custom-domains), secured via [automated certificate management](https://devcenter.heroku.com/articles/automated-certificate-management).

A single [Terraform config](https://www.terraform.io/docs/configuration/index.html) embodies the complete system, enabling high-level collaboration, repeatability, test-ability, and change management.

![Diagram: Terraform a complete multi-app
architecture with Heroku Private Spaces, 
a Kong gateway, & DNSimple](doc/terraform-heroku-kong-microservices-v03.png)

## Primary components

* [Heroku](https://www.heroku.com/home) provides the primatives: Private Spaces, Apps, and Add-ons
* [Kong CE](https://konghq.com/kong-community-edition/) provides a high-performance HTTP proxy/gateway with [plugins](https://konghq.com/plugins/) supporting access control, flow control, logging, circuit-breaking, and more including custom plugins
* [Terraform](https://terraform.io) provides declarative, unified systems configuration with support for over 120 providers, a human-friendly configuration as code format, and a deterministic provisioning engine
* [DNSimple](https://dnsimple.com) provides API-driven domain name configuration.

## Challenges & Caveats

* **Connecting the Terraform config with Heroku slugs.** This proof-of-concept [contains slug archives](slugs/) that were manually extracted with the Heroku API from pre-existing apps. While there's a higher-level conceptual challenge with the design of this interconnection between Heroku DX & Terraform, there are use-cases this proof-of-concept still serves, such as  using Heroku Pipelines purely as a build & QA system ([example](https://github.com/mars/tinyrobot-science-terraform)), and with an external CI/build system creating slug archives for Terraform.
* **Renaming Terraform-provisioned Heroku apps.** If apps are renamed, Terraform can no longer access various resources without first manually editing, revising `terraform.tfstate` with the new names. See **terraform-provider-heroku** issues [#124](https://github.com/terraform-providers/terraform-provider-heroku/issues/124) & [#93](https://github.com/terraform-providers/terraform-provider-heroku/issues/93)

## Requirements

* [Heroku](https://www.heroku.com/home)
  * install [command-line tools (CLI)](https://toolbelt.heroku.com)
  * [an account](https://signup.heroku.com) (must be a member of an Enterprise account for access to Private Spaces)
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

-----

🔬 This is a community proof-of-concept, [MIT license](LICENSE), provided "as is", without warranty of any kind.
