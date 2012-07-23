# -*- coding: utf-8 -*-
require 'yaml'
require 'evernote'

module LastfmDailyEver
  VERSION = '0.0.1'
  
  class << self
    # 設定のロード
    def load_config(path)
      File.exists?(path) ? YAML.load_file(path) : ENV
    end
    
    # clockwork実行時間設定
    def clock_time
      path = File.dirname(__FILE__) + "/../config/clock.yml"
      load_config(path)["schedule"]
    end
    
    # Evernote設定
    def evernote_config
      path = File.dirname(__FILE__) + "/../config/evernote.yml"
      load_config(path)
    end
    
    # Evernote認証情報
    def evernote_auth_token
      path = File.dirname(__FILE__) + "/../config/evernote.auth.yml"
      load_config(path)
    end
    
    def run
      config = evernote_config["from"]
      evernote = LastfmDailyEver::MyEvernote.new(evernote_auth_token["auth_token"])
      list = evernote.get_note_in_today(config["notebook"], config["stack"], config["limit"])
      config = evernote_config["to"]
      evernote.add_note(list, config["notebook"], config["stack"], config["tags"])
    end
  end
end