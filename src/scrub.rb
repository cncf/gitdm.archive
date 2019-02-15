#!/usr/bin/env ruby

# :%s/^M//g
# To enter ^M, type CTRL-V, then CTRL-M

contents = File.read(ARGV[0]).scrub
#contents.delete! ''
contents.delete! "\r"
File.write(ARGV[0], contents)
