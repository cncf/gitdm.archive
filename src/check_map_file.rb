require 'pry'
require 'json'

def check_map_file(map_file)
  affs = {}
  File.readlines(map_file).each do |line|
    line.strip!
    if line.length > 0 && line[0] == '#'
      puts line
      next
    end
    ary = line.split ' '
    email = ary[0]
    aff = ary[1..-1].join(' ')
    affs[email] = [] unless affs.key?(email)
    affs[email] << aff
  end
  affs.keys.sort.each do |email|
    lst = []
    spec = []
    affs[email].each do |aff|
      if aff.include?(' < ')
        lst << aff
        next
      end
      spec << aff
    end
    if spec.length == 1
      lst << spec.first
    else
      final = ''
      conflict = false
      spec.each do |s|
        next if s == 'NotFound'
        final = s if final == ''
        if final != s
          STDERR.puts "Error: email: #{email} '#{final}' != '#{s}'"
          conflict = true
        end
      end
      if spec.length > 1
        final = 'NotFound' if final == ''
        lst << final
      end
    end
    lst.sort.each  do |s|
      puts "#{email} #{s}"
    end
  end
end

if ARGV.size < 1
  puts "Missing argument: cncf-config/email-map"
  exit(1)
end

check_map_file(ARGV[0])
