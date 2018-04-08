namespace :load do
  task :defaults do
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
  end
end

namespace :nginx_unit do
  desc "Start NGINX Unit process"
  task :start do
    on release_roles(fetch(:nginx_unit_roles)) do
      pid_file = fetch(:nginx_unit_pid)
      if test("[ -e #{pid_file} ] && kill -0 `cat #{pid_file}`")
        info "NGINX Unit is already started"
      else
        execute :sudo, :unitd,
                "--pid #{pid_file}",
                "--control unix:#{fetch(:nginx_unit_control_sock)}",
                fetch(:nginx_unit_options)
      end
    end
  end

  # NOTE: Should we detach listener and application before killing?
  desc "Stop NGINX Unit process"
  task :stop do
    on release_roles(fetch(:nginx_unit_roles)) do
      pid_file = fetch(:nginx_unit_pid)
      if test("[ -e #{pid_file} ] && kill -0 `cat #{pid_file}`")
        execute :sudo, :kill, "-s QUIT `cat #{pid_file}`"
      else
        info "NGINX Unit is already stopped"
      end
    end
  end

  # If you want to apply new code when deployed,
  # please invoke this task after deploy:published
  desc "Attach listener and application configuration to NGINX Unit"
  task :attach do
    invoke "nginx_unit:start"
    invoke "nginx_unit:attach_app"
    invoke "nginx_unit:attach_listener"
  end

  desc "Attach listener configuration to NGINX Unit"
  task :attach_listener do
    on release_roles(fetch(:nginx_unit_roles)) do
      listener_json = JSON.generate("application" => fetch(:application))
      control_nginx_unit(:put, path: "/listeners/#{fetch(:nginx_unit_listen)}", json: listener_json)
    end
  end

  desc "Attach application configuration to NGINX Unit"
  task :attach_app do
    on release_roles(fetch(:nginx_unit_roles)) do |role|
      released_dir = capture(:readlink, "-f", current_path)
      raise "Doesn't exist released dir: #{released_dir}" unless test("[ -d #{released_dir} ]")

      app_json = JSON.generate({
        type:      "ruby",
        processes: fetch(:nginx_unit_processes),
        user:      fetch(:nginx_unit_user) || role.user,
        group:     fetch(:nginx_unit_group) || role.user,
        script:    File.join(released_dir, fetch(:nginx_unit_script))
      })

      control_nginx_unit(:put, path: "/applications/#{fetch(:nginx_unit_app_name)}", json: app_json)
    end
  end

  desc "Detach listener and application configuration from NGINX Unit"
  task :detach do
    invoke "nginx_unit:detach_listener"
    invoke "nginx_unit:detach_app"
  end

  desc "Detach listener configuration from NGINX Unit"
  task :detach_listener do
    on release_roles(fetch(:nginx_unit_roles)) do
      control_nginx_unit(:delete, path: "/listeners/#{fetch(:nginx_unit_listen)}")
    end
  end

  desc "Detach application configuration from NGINX Unit"
  task :detach_app do
    on release_roles(fetch(:nginx_unit_roles)) do
      control_nginx_unit(:delete, path: "/applications/#{fetch(:nginx_unit_app_name)}")
    end
  end

  # Send request to NGINX Unit control socket
  def control_nginx_unit(method, path: "", json: nil)
    args = [
      "-fs",
      "-X #{method.to_s.upcase}",
      "--unix-socket #{fetch(:nginx_unit_control_sock)}",
      "'http://localhost/#{path}'"
    ]

    args << "-d '#{json}'" if json

    execute :curl, *args
  end
end
