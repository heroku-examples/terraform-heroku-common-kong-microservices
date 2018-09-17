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
  version = "~> 1.4"
}

provider "kong" {
  version = "~> 1.7"

  # Optional: use insecure until DNS is ready at dnsimple
  # kong_admin_uri = "${local.kong_insecure_admin_uri}"
  kong_admin_uri = "${local.kong_admin_uri}"

  kong_api_key = "${random_id.kong_admin_api_key.b64_url}"
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
  app  = "${heroku_app.kong.id}"
  plan = "heroku-postgresql:hobby-dev"
}

resource "heroku_slug" "kong" {
  app                            = "${heroku_app.kong.id}"
  buildpack_provided_description = "Kong"
  file_path                      = "slugs/kong.tgz"

  process_types = {
    release = "bin/heroku-buildpack-kong-release"
    web     = "bin/heroku-buildpack-kong-web"
  }
}

resource "heroku_app_release" "kong" {
  app     = "${heroku_app.kong.id}"
  slug_id = "${heroku_slug.kong.id}"

  depends_on = ["heroku_addon.kong_pg"]
}

resource "heroku_formation" "kong" {
  app        = "${heroku_app.kong.id}"
  type       = "web"
  quantity   = 1
  size       = "Standard-1x"
  depends_on = ["heroku_app_release.kong"]

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

resource "heroku_slug" "wasabi" {
  app                            = "${heroku_app.wasabi.id}"
  buildpack_provided_description = "Node.js"
  file_path                      = "slugs/wasabi-secure.tgz"

  process_types = {
    web = "npm start"
  }
}

resource "heroku_app_release" "wasabi" {
  app     = "${heroku_app.wasabi.id}"
  slug_id = "${heroku_slug.wasabi.id}"
}

resource "heroku_formation" "wasabi" {
  app        = "${heroku_app.wasabi.id}"
  type       = "web"
  quantity   = 1
  size       = "Standard-1x"
  depends_on = ["heroku_app_release.wasabi"]
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

output "wasabi_service_url" {
  value = "${local.kong_base_url}/wasabi"
}
