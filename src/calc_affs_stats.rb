require 'pry'
require 'json'
require './comment'
require './email_code'
require './ghapi'
require './merge'
require './mgetc'

def calc_affs_stats(email_map_file, json_file, all_actors_file, cncf_actors_file)
  # parse current email-map, store data in 'eaffs'
  eaffs = {}
  File.readlines(email_map_file).each do |line|
    line.strip!
    if line.length > 0 && line[0] == '#'
      next
    end
    ary = line.split ' '
    email = ary[0]
    aff = ary[1..-1].join(' ')
    eaffs[email] = aff == 'NotFound' ? false : true
  end
  binding.pry
end

if ARGV.size < 4
  puts "Missing arguments: email_map_file json_file all_actors_file cncf_actors_file (cncf-config/email-map github_users.json actors.txt actors_cncf.txt)"
  exit(1)
end

calc_affs_stats(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
