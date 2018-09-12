# Terraform microservices with a unified gateway on Heroku

## Usage

1. Install [git-lfs](https://git-lfs.github.com) (efficiently supports checking Heroku app slugs into version control)
2. `git clone` this repo and `cd` into it
3. Install [terraform-provider-kong 1.7.0](https://github.com/kevholditch/terraform-provider-kong/releases/tag/v1.7.0)
    * download the `.zip` asset for your computer's architecture
    * unzip it into `terraform.d/plugins/$ARCH/`
    * where `$ARCH` is the computer's architecture, like `darwin_amd64`
4. Set Heroku API key
    1. `heroku authorizations:create -d terraform-heroku-kong-microservices`
    2. `export HEROKU_API_KEY=<"Token" value from the authorization>`
5. Set [dnsimple credentials](https://support.dnsimple.com/articles/api-access-token/)
    * `export DNSIMPLE_ACCOUNT=xxxxx DNSIMPLE_TOKEN=yyyyy`
6. `terraform init`
7. `terraform apply -var name=kong-micro -var dns_zone=example.com -var heroku_enterprise_team=example-team -var hello_world_header_message=🦋`