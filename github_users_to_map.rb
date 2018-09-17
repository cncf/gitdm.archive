require 'json'

def github_users_to_map(json_file)
  # Parse JSON
  data = JSON.parse File.read json_file

  # Skip
  skip_set = ['Independent', 'NotFound', '?', '(Unknown)', '-', 'Funky']

  data.each do |user|
    email = user['email'].downcase
    aff = user['affiliation']
    next if skip_set.include?(aff)
    next unless email.include?('!')
    ary = user['affiliation'].split(', ')
    ary.each { |a| puts "#{email} #{a}" }
  end
end

if ARGV.size < 1
  puts "Missing argument: JSON file"
  exit(1)
end

github_users_to_map(ARGV[0])
