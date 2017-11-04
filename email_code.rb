def email_decode(line)
  return nil unless line
  line.gsub(/[^\s!]+![^\s!]+/) { |email| email.sub('!', '@') }
end

def email_encode(line)
  return nil unless line
  line.gsub(/[^\s@]+@[^\s@]+/) { |email| email.sub('@', '!') }
end

