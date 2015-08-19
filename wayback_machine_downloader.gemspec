require './lib/wayback_machine_downloader'

Gem::Specification.new do |s|
  s.name        = "wayback_machine_downloader"
  s.version     = WaybackMachineDownloader::VERSION
  s.executables << "wayback_machine_downloader"
  s.summary     = "Download any website from the Wayback Machine."
  s.description = "Download any website from the Wayback Machine. Wayback Machine by Internet Archive (archive.org) is an awesome tool to view any website at any point of time but lacks an export feature. Wayback Machine Downloader brings exactly this."
  s.authors     = ["hartator"]
  s.email       = "hartator@gmail.com"
  s.files       = ["lib/wayback_machine_downloader.rb", "lib/wayback_machine_downloader/tidy_bytes.rb"]
  s.homepage    = "https://github.com/hartator/wayback-machine-downloader"
  s.license     = "MIT"
  s.required_ruby_version = '>= 1.9.2'
  s.add_development_dependency 'pry-rescue', '~> 1.4'
  s.add_development_dependency 'pry-stack_explorer', '~> 0.4'
end
