
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "capistrano/nginx-unit/version"

Gem::Specification.new do |spec|
  spec.name          = "capistrano-nginx-unit"
  spec.version       = Capistrano::NGINX_UNIT_VERSION
  spec.authors       = ["murakmii"]
  spec.email         = ["bonono.jp@gmail.com"]

  spec.summary       = "The Capistrano 3.x task to run rack application on NGINX Unit"
  spec.description   = "The Capistrano 3.x task to run rack application on NGINX Unit"
  spec.homepage      = "https://github.com/murakmii/capistrano-nginx-unit"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.add_runtime_dependency "capistrano", "~> 3.0"
end
