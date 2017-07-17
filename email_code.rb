def email_decode(line)
  line.gsub(/[^\s!]+![^\s!]+/) { |email| email.sub('!', '@') }
end

def email_encode(line)
  line.gsub(/[^\s@]+@[^\s@]+/) { |email| email.sub('@', '!') }
end

