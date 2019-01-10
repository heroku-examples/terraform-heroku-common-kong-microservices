variable "name" {
  type = "string"
}

variable "heroku_team" {
  type = "string"
}

variable "heroku_region" {
  type    = "string"
  default = "us"
}

locals {
  kong_app_name  = "${var.name}-proxy"
  kong_base_url  = "https://${local.kong_app_name}.herokuapp.com"
  kong_admin_uri = "${local.kong_base_url}/kong-admin"
}

provider "heroku" {
  version = "~> 1.7"
}

provider "kong" {
  version = "~> 1.9"

  kong_admin_uri = "${local.kong_admin_uri}"
  kong_api_key   = "${random_id.kong_admin_api_key.b64_url}"
}

provider "random" {
  version = "~> 2.0"
}

resource "random_id" "kong_admin_api_key" {
  byte_length = 32
}

# Proxy app

resource "heroku_app" "kong" {
  name   = "${local.kong_app_name}"
  acm    = true
  region = "${var.heroku_region}"

  config_vars {
    KONG_HEROKU_ADMIN_KEY = "${random_id.kong_admin_api_key.b64_url}"
  }

  organization {
    name = "${var.heroku_team}"
  }
}

resource "heroku_addon" "kong_pg" {
  app  = "${heroku_app.kong.name}"
  plan = "heroku-postgresql:hobby-dev"
}

# The Kong Provider is not yet compatible with Kong 1.0 (buildpack & app v7.0),
# so instead use 0.14 (buildpack & app v6.0).
resource "heroku_build" "kong" {
  app        = "${heroku_app.kong.name}"
  buildpacks = ["https://github.com/heroku/heroku-buildpack-kong#v6.0.0"]

  source = {
    # This app uses a community buildpack, set it in `buildpacks` above.
    url     = "https://github.com/heroku/heroku-kong/archive/v6.0.1.tar.gz"
    version = "v6.0.1"
  }
}

resource "heroku_formation" "kong" {
  app        = "${heroku_app.kong.name}"
  type       = "web"
  quantity   = 1
  size       = "Standard-1x"
  depends_on = ["heroku_build.kong"]

  provisioner "local-exec" {
    command = "./bin/kong-health-check ${local.kong_base_url}/kong-admin"
  }
}

# Microservice app w/ proxy config

resource "random_id" "wasabi_internal_api_key" {
  byte_length = 32
}

resource "heroku_app" "wasabi" {
  name   = "${var.name}-wasabi"
  acm    = true
  region = "${var.heroku_region}"

  config_vars {
    INTERNAL_API_KEY = "${random_id.wasabi_internal_api_key.b64_url}"
  }

  organization {
    name = "${var.heroku_team}"
  }
}

resource "heroku_build" "wasabi" {
  app        = "${heroku_app.wasabi.name}"
  buildpacks = ["https://github.com/heroku/heroku-buildpack-nodejs"]

  source = {
    # This app uses a community buildpack, set it in `buildpacks` above.
    url     = "https://github.com/mars/wasabi-secure/archive/v1.0.0.tar.gz"
    version = "v1.0.0"
  }
}

resource "heroku_formation" "wasabi" {
  app        = "${heroku_app.wasabi.name}"
  type       = "web"
  quantity   = 1
  size       = "Standard-1x"
  depends_on = ["heroku_build.wasabi"]
}

resource "kong_service" "wasabi" {
  name       = "wasabi"
  protocol   = "https"
  host       = "${heroku_app.wasabi.name}.herokuapp.com"
  port       = 443
  depends_on = ["heroku_formation.kong"]
}

resource "kong_route" "wasabi_hostname" {
  protocols  = ["https"]
  paths      = ["/wasabi"]
  strip_path = true
  service_id = "${kong_service.wasabi.id}"
}

resource "kong_plugin" "wasabi_internal_api_key" {
  name       = "request-transformer"
  service_id = "${kong_service.wasabi.id}"

  config = {
    add.headers = "X-Internal-API-Key: ${random_id.wasabi_internal_api_key.b64_url}"
  }
}

output "wasabi_backend_url" {
  value = "https://${heroku_app.wasabi.name}.herokuapp.com"
}

output "wasabi_public_url" {
  value = "${local.kong_base_url}/wasabi"
}
