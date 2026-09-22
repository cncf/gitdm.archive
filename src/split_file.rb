require 'pry'

def split_files(files)
  max_size = 950*1024
  files.each do |file|
    header = ''
    data = ''
    contents = ''
    n = 1
    File.readlines(file).each do |line|
      if line[0] == '#'
        header += line
      elsif line[0] == "\t"
        data += line
      else
        if contents.length + data.length  + line.length >= max_size
          ary = file.split('.')
          l = ary.length
          fn = "#{ary[0..l-2].join('.')}#{n}.#{ary[l-1]}"
          puts fn
          File.write fn, header + contents
          contents = data
          n += 1
        else
          contents += data
        end
        data = line
      end
    end
    ary = file.split('.')
    l = ary.length
    fn = "#{ary[0..l-2].join('.')}#{n}.#{ary[l-1]}"
    puts fn
    File.write fn, header + contents + data
  end
end

if ARGV.size < 1
  puts "Missing argument(s): (../company_developers.txt ../developers-affiliations.txt)"
  exit(1)
end

split_files(ARGV)
