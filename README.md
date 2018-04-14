# capistrano-nginx-unit

## Installation

```rb
# Gemfile
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

`nginx_unit:attach` is main task.  
The task [sends HTTP request to configure NGINX Unit](http://unit.nginx.org/configuration/) on server.  
When NGINX Unit process received the request, launches rack application process.  
If you want to apply new code when deployed, please invoke `nginx_unit:attach` task after `deploy:published`.

```rb
# deploy.rb
after "deploy:published", "nginx_unit:attach"
```

## Options

```rb
set :nginx_unit_roles,        -> { :app }
set :nginx_unit_control_sock, -> { "/var/run/control.unit.sock" }
set :nginx_unit_listen,       -> { "*:3000" }
set :nginx_unit_app_name,     -> { fetch(:application) }
set :nginx_unit_processes,    -> { nil }
set :nginx_unit_user,         -> { nil }
set :nginx_unit_group,        -> { nil }
set :nginx_unit_working_dir,  -> { nil }
set :nginx_unit_script,       -> { "config.ru" }
```

 - `:nginx_unit_roles`
   
   Roles to run tasks for NGINX Unit. Default: `:app`

 - `:nginx_unit_control_sock`

   Path to NGINX Unit's unix domain socket path. Default: `"/var/run/control.unit.sock"`

 - `:nginx_unit_listen`
  
   IP Address and port where rack application listens on. Default: `"*:3000"`    
   See [Listeners configuration](https://unit.nginx.org/configuration/#listeners)

 - `:nginx_unit_app_name`

   Application name.  
   See [Applications configuration](https://unit.nginx.org/configuration/#applications)

 - `:nginx_unit_processes`
   
   Number of rack application processes. Default: `1`  
   See [Application Object configuration](https://unit.nginx.org/configuration/#application-objects)

 - `:nginx_unit_user`
 - `:nginx_unit_group`

   Username and group of rack application process. Default: `"nobody"`  
   See [Application Object configuration](https://unit.nginx.org/configuration/#application-objects)

 - `:nginx_unit_working_dir`

   Working directory of rack application process. Default: `RELEASE_PATH`  
   See [Application Object configuration](https://unit.nginx.org/configuration/#application-objects)

 - `:nginx_unit_script`

   Rack application script path. Default: `RELEASE_PATH/config.ru`  
   See [Ruby application configuration](https://unit.nginx.org/configuration/#ruby-application)
   