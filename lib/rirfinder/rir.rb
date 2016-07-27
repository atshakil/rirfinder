#!/usr/bin/env ruby

require 'httparty'

class RIRFinder::RIR
  def initialize db, rir, tmp = '/tmp/rir'
    @rir_index = [:afrinic, :apnic, :arin, :lacnic, :ripe]
    @db = db
    @rir = if rir == :all
      @rir_index
    else
       rir.class == Array ? rir : Array.new.push(rir)
    end
    @tmp = tmp and Dir.mkdir tmp rescue nil
  end

  def build_db
    _fetch @rir
    _parse
    # TODO
  end

  def _fetch rir_list
    rir_list.each do |rir|
      fp = open @tmp + "/#{rir}", 'w'
      fp.write HTTParty.get("http://ftp.#{rir}.net/pub/stats/#{rir}/delegated-#{rir}-extended-latest")
      fp.close
    end
  end

  def _parse
    reports = Hash.new
    ignore_initial_lines = 4
    Dir.chdir @tmp
    (Dir.entries(@tmp) - ['.', '..']).each do |report|
      fp = open report
      reports[report] = fp.read.lines.select{|line| line[0] != '#'}[ignore_initial_lines..-1]
        .map{|line| line.split '|'}
      fp.close
    end
    reports
  end

  class << self
    def generate args = {db: 'rir.db', rir: :all, fetch: false}
      if args[:fetch]
        self.new(args[:db], args[:rir]).build_db
      else
        self.new(args[:db], args[:rir])._parse
      end
    end
  end
end

