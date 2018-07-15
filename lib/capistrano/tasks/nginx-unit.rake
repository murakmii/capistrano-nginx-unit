namespace :load do
  task :defaults do
    set :nginx_unit_roles,        -> { :app }
    set :nginx_unit_control_sock, -> { "/var/run/control.unit.sock" }
    set :nginx_unit_listen,       -> { "*:3000" }
    set :nginx_unit_app_name,     -> { fetch(:application) }
    set :nginx_unit_processes,    -> { nil }
    set :nginx_unit_user,         -> { nil }
    set :nginx_unit_group,        -> { nil }
    set :nginx_unit_working_dir,  -> { nil }
    set :nginx_unit_script,       -> { "config.ru" }
    set :nginx_unit_environment,  -> { {} }
  end
end

namespace :nginx_unit do
  # NOTE: Should we detach listener and application before stopping?
  [:start, :stop].each do |cmd|
    desc "#{cmd.to_s.capitalize} NGINX Unit process"
    task cmd do
      on release_roles(fetch(:nginx_unit_roles)) do
        if test(:which, :systemctl)
          sudo :systemctl, cmd, :unit
        else
          sudo :service, :unit, cmd
        end
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
    on release_roles(fetch(:nginx_unit_roles)) do
      released_dir = capture(:readlink, "-f", current_path)
      raise "Doesn't exist released dir: #{released_dir}" unless test("[ -d #{released_dir} ]")

      app_json = JSON.generate({
        type: "ruby",
        processes: fetch(:nginx_unit_processes),
        user: fetch(:nginx_unit_user),
        group: fetch(:nginx_unit_group),
        working_directory: fetch(:nginx_unit_working_dir) || released_dir,
        script: File.join(released_dir, fetch(:nginx_unit_script)),
        environment: fetch(:nginx_unit_environment)
      }.reject { |_, v| v.respond_to?(:empty?) ? v.empty? : v.nil? })

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
      listen = fetch(:nginx_unit_listen)

      if nginx_unit_conf["listeners"][listen]
        control_nginx_unit(:delete, path: "/listeners/#{listen}")
      else
        info "Listener \"#{listen}\" is already detached"
      end
    end
  end

  desc "Detach application configuration from NGINX Unit"
  task :detach_app do
    on release_roles(fetch(:nginx_unit_roles)) do
      app_name = fetch(:nginx_unit_app_name)

      if nginx_unit_conf["applications"][app_name]
        control_nginx_unit(:delete, path: "/applications/#{app_name}")
      else
        info "Application \"#{app_name}\" is already detached"
      end
    end
  end

  # Send request to NGINX Unit control socket
  def control_nginx_unit(method, path: "", json: nil)
    args = [
      "-s",
      "-X #{method.to_s.upcase}",
      "--unix-socket #{fetch(:nginx_unit_control_sock)}",
      "'http://localhost/#{path}'"
    ]

    args << "-d '#{json}'" if json

    res = JSON.parse(capture(:sudo, :curl, *args))
    if res["error"]
      error res.inspect
      raise "NGINX Unit: #{res["error"]}"
    else
      info res.inspect
    end
  end

  # Get current configuration
  def nginx_unit_conf
    JSON.parse(capture(
      :sudo, :curl,
      "--unix-socket #{fetch(:nginx_unit_control_sock)}",
      "http://localhost/"
    ))
  end
end
