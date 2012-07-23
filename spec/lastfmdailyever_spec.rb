# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec/spec_helper')

describe LastfmDailyEver, 'が実行する処理' do
  before do
    @evernote_auth_token = LastfmDailyEver.evernote_auth
    @evernote_config = LastfmDailyEver.evernote_config
  end
  
  describe 'Evernote処理' do
    let(:evernote) { 
      LastfmDailyEver::MyEvernote.new(@evernote_auth_token)
    }
    
    it "指定したノートブックから今日のノートのリストを取得できること" do
      config = @evernote_config["from"]
      list = evernote.get_note_in_today(config["notebook"], config["stack"], config["limit"])
      list.should_not be_empty
    end
    
    it "今日の聞いた音楽情報の登録が成功すること" do
      config = @evernote_config["from"]
      list = evernote.get_note_in_today(config["notebook"], config["stack"], config["limit"])
      config = @evernote_config["to"]
      res = evernote.add_note(list, "Development", nil, config["tags"])
      # notebook: Development
      res.notebookGuid.should == "2c2b6d3a-9f5a-48a2-9a40-8d617cc556d7"
      # tag: Last.fm
      res.tagGuids[0].should == "e554deb8-7777-48db-afa0-9c76d06e6d33"
      # tag: LifeLog
      res.tagGuids[1].should == "f0a37dfa-d795-41fa-b68c-4b84373fae77"
      # tag: Last.fm - Daily
      res.tagGuids[2].should == "3c5c248b-bd7f-43df-bed8-0d3a12a519d3"
    end
  end
end
