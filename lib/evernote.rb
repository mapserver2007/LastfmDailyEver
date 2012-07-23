# -*- coding: utf-8 -*-
$: << File.dirname(__FILE__) + "/evernote/lib"
$: << File.dirname(__FILE__) + "/evernote/lib/thrift"
$: << File.dirname(__FILE__) + "/evernote/lib/Evernote/EDAM"

require "thrift/types"
require "thrift/struct"
require "thrift/protocol/base_protocol"
require "thrift/protocol/binary_protocol"
require "thrift/transport/base_transport"
require "thrift/transport/http_client_transport"
require "Evernote/EDAM/user_store"
require "Evernote/EDAM/user_store_constants.rb"
require "Evernote/EDAM/note_store"
require "Evernote/EDAM/limits_constants.rb"
require 'active_support'
require 'digest/md5'

module LastfmDailyEver
  EVERNOTE_URL = "https://www.evernote.com/edam/user"
  
  class MyEvernote
    def initialize(auth_token)
      @auth_token = auth_token
      userStoreTransport = Thrift::HTTPClientTransport.new(EVERNOTE_URL)
      userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
      user_store = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)
      noteStoreUrl = user_store.getNoteStoreUrl(@auth_token)
      noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
      noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
      @note_store = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    end
    
    def add_note(list, notebook, stack, tags)
      note = Evernote::EDAM::Type::Note.new
      note.title = to_ascii(Time.now.strftime("%Y年%m月%d日") + "に聞いた音楽")
      note.content = create_content(list)
      note.notebookGuid  = get_notebook_guid(notebook, stack)
      note.tagGuids = get_tag_guid(tags)
      @note_store.createNote(@auth_token, note)
    end
    
    def get_note_in_today(notebook, stack = nil, limit = 0)
      notebook_guid = get_notebook_guid(notebook, stack)
      # 検索条件
      filter = Evernote::EDAM::NoteStore::NoteFilter.new
      filter.order = Evernote::EDAM::Type::NoteSortOrder::CREATED
      filter.notebookGuid = notebook_guid
      filter.timeZone = "Asia/Tokyo"
      filter.ascending = false # descending
      # ノート取得
      note_list = @note_store.findNotes(@auth_token, filter, 0, limit)
      daily_note = {}
      note_list.notes.each do |note|
        # 末尾3桁が0で埋まっているので除去する
        created_at = note.created.to_s
        unix_time = created_at.slice(0, created_at.length - 3)
        note_date = Time.at(unix_time.to_f)
        # 今日の日付のノートのみ取得する
        now = Time.now
        break unless now.month == note_date.month && now.day == note_date.day
        # タイトルをハッシュにしてキーとする
        key = Digest::MD5.hexdigest(note.title)
        
        if daily_note[key].nil?
          daily_note[key] = {
            :title => note.title,
            :playcount => 1
          }
        else
          daily_note[key][:playcount] += 1
        end
      end
      
      # 再生回数が多い順に降順ソート
      daily_note.sort_by {|k, v| v[:playcount] * -1}.inject [] do |daily_notes, note|
        # ハッシュを文字列にしてリストに格納する
        daily_notes << "#{note[1][:title]}(#{note[1][:playcount].to_s})"
      end
    end
    
    private
    def to_ascii(str)
      str.force_encoding("ASCII-8BIT") unless str.nil?
    end
    
    def get_notebook_guid(notebook_name, stack_name = nil)
      notebook_name = to_ascii(notebook_name)
      stack_name = to_ascii(stack_name)
      @note_store.listNotebooks(@auth_token).each do |notebook|
        if notebook.name == notebook_name && notebook.stack == stack_name
          return notebook.guid
        end
      end
    end
    
    def get_tag_guid(tag_list)
      tag_list.map!{|tag| to_ascii(tag)}
      @note_store.listTags(@auth_token).each_with_object [] do |tag, list|
        if tag_list.include? tag.name
          list << tag.guid
        end
      end
    end

    def create_content(list)
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + 
      "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml.dtd\">" +
      "<en-note>%s</en-note>"
      if list.empty?
        xml % to_ascii("今日聞いた音楽はありません。")
      else
      no = 1
        xml % (list.each_with_object "" do |data, html|
          html << "<div><![CDATA[#{no}: #{to_ascii(data)}]]></div>"
          no += 1
        end)
      end
    end
  end
end

