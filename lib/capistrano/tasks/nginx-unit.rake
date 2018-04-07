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

# TODO: Stop NGINX Unit process
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

  # If you want to apply new code when deployed,
  # please invoke this task after deploy:published
  desc "Set listener and application configuration for NGINX Unit"
  task :configure do
    invoke "nginx_unit:configure_app"
    invoke "nginx_unit:configure_listener"
  end

  desc "Set listener configuration for NGINX Unit"
  task :configure_listener do
    on release_roles(fetch(:nginx_unit_roles)) do
      listener_json = JSON.generate("application" => fetch(:application))

      configure_nginx_unit("/listeners/#{fetch(:nginx_unit_listen)}", listener_json)
    end
  end

  desc "Set application configuration for NGINX Unit"
  task :configure_app do
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

      info "application config: #{app_json}"
      configure_nginx_unit("/applications/#{fetch(:nginx_unit_app_name)}", app_json)
    end
  end

  # Send request to NGINX Unit control socket
  def configure_nginx_unit(path, json)
    info "#{path} => #{json}"

    res = JSON.parse(capture(:curl,
      "-X PUT",
      "-d '#{json}'",
      "--unix-socket #{fetch(:nginx_unit_control_sock)}",
      "'http://localhost/#{path}'"
    ))

    if res["error"]
      fatal res
      raise "Faild to configure"
    else
      info res
    end
  end
end
