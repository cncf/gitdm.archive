#!/usr/bin/env ruby
require './email_code'

def decode_emails(input, output)
  File.open(output, 'w') do |file|
    File.readlines(input).each do |line|
      file.write email_decode(line)
      #file.write line
    end
  end
end

if ARGV.size < 2
  puts "Missing arguments: input_file output_file"
  exit(1)
end

decode_emails(ARGV[0], ARGV[1])
