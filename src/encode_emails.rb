#!/usr/bin/env ruby
require './email_code'

def encode_emails(input, output)
  File.open(output, 'w') do |file|
    File.readlines(input).each do |line|
      file.write email_encode(line)
      #file.write line
    end
  end
end

if ARGV.size < 2
  puts "Missing arguments: input_file output_file"
  exit(1)
end

encode_emails(ARGV[0], ARGV[1])
