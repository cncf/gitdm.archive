#!/usr/bin/env ruby

contents = File.read(ARGV[0]).scrub
File.write(ARGV[0], contents)
