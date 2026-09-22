#!/usr/bin/env ruby
require 'csv'
require 'digest'

def handle_forbidden_data(filenames)
  # Read the forbidden list
  config_file = 'cncf-config/forbidden.csv'
  shas = {}
  CSV.foreach(config_file, headers: true) do |row|
    h = row.to_h
    sha = h['sha']
    shas[sha] = true
    # puts "Forbidden SHA: '#{sha}'"
  end

  # Process files
  sha256 = Digest::SHA256.new
  added = false
  split_exp = /[\s+,;'"\/\\]/
  filenames.each do |filename|
    File.readlines(filename).each_with_index do |line, line_num|
      begin
        line.split(split_exp).reject(&:empty?).each do |token|
          sha = sha256.hexdigest token.strip
          puts "File: #{filename}, Line: #{line_num + 1}, Token: #{token}, SHA: #{sha}" if shas.key?(sha)
        end
      rescue ArgumentError => e
        next
      end
    end
  end
end

if ARGV.size < 1
  puts "Missing arguments: file1 file2 ..."
  exit(1)
end

handle_forbidden_data(ARGV)
