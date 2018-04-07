# capistrano-nginx-unit

## Installation

```rb
gem "capistrano-nginx-unit"
```

## Usage

Require in Capfile.

```rb
# Capfile
require "capistrano/nginx-unit"
```

Defined three tasks.

```
cap nginx_unit:configure           # Set listener and application configuration for NGINX Unit
cap nginx_unit:configure_app       # Set application configuration for NGINX Unit
cap nginx_unit:configure_listener  # Set listener configuration for NGINX Unit
```

Defined some customizable options.

```rb
set :nginx_unit_roles,        -> { :app }
set :nginx_unit_control_sock, -> { "/var/run/control.unit.sock" }
set :nginx_unit_listen,       -> { "*:3000" }
set :nginx_unit_app_name,     -> { fetch(:application) }
set :nginx_unit_processes,    -> { 1 }
set :nginx_unit_user,         -> { nil }
set :nginx_unit_group,        -> { nil }
set :nginx_unit_script,       -> { "config.ru" }
```

If you want to apply new code when deployed, please invoke `nginx_unit:configure` task after `deploy:published`.

```rb
# deploy.rb
after "deploy:published", "nginx_unit:configure"
```
