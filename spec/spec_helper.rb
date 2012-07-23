require 'rspec'
require 'yaml'
require File.dirname(__FILE__) + "/../lib/evernote"

module LastfmDailyEver
  class << self
    def evernote_auth
      path = File.dirname(__FILE__) + "/../config/evernote.auth.yml"
      YAML.load_file(path)["auth_token"]
    end
    
    def evernote_config
      path = File.dirname(__FILE__) + "/../config/evernote.yml"
      YAML.load_file(path)
    end
  end
end