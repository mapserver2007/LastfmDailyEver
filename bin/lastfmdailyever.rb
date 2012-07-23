# -*- coding: utf-8 -*-
$: << File.dirname(__FILE__) + "/../lib"
require 'lastfmdailyever'
require 'clockwork'
include Clockwork

schedule = LastfmDailyEver.clock_time
handler {|job| job.run }
every(1.day, LastfmDailyEver, :at => schedule)