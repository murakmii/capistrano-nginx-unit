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

Defined following tasks.

```
cap nginx_unit:attach              # Attach listener and application configuration to NGINX Unit
cap nginx_unit:attach_app          # Attach application configuration to NGINX Unit
cap nginx_unit:attach_listener     # Attach listener configuration to NGINX Unit
cap nginx_unit:detach              # Detach listener and application configuration from NGINX Unit
cap nginx_unit:detach_app          # Detach application configuration from NGINX Unit
cap nginx_unit:detach_listener     # Detach listener configuration from NGINX Unit
cap nginx_unit:start               # Start NGINX Unit process
cap nginx_unit:stop                # Stop NGINX Unit process
```

Defined following customizable options.

```rb
set :nginx_unit_roles,        -> { :app }
set :nginx_unit_pid,          -> { "/var/run/unit.pid" }
set :nginx_unit_control_sock, -> { "/var/run/control.unit.sock" }
set :nginx_unit_options,      -> { "" }
set :nginx_unit_listen,       -> { "*:3000" }
set :nginx_unit_app_name,     -> { fetch(:application) }
set :nginx_unit_processes,    -> { 1 }
set :nginx_unit_user,         -> { nil }
set :nginx_unit_group,        -> { nil }
set :nginx_unit_script,       -> { "config.ru" }
```

If you want to apply new code when deployed, please invoke `nginx_unit:attach` task after `deploy:published`.

```rb
# deploy.rb
after "deploy:published", "nginx_unit:attach"
```
