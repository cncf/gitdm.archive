require 'json'

def sort_affs(affs)
  return affs if affs.nil?
  affs.split(', ').sort.join(', ')
end

def check_affs_list(key, affiliations, guess, verbose)
  unknowns = []
  ranges = []
  finals = []
  affiliations.each do |affiliation|
    if ['?', 'NotFound', '(Unknown)'].include?(affiliation)
      unknowns << affiliation
    else
      if affiliation.include? ' < '
        ranges << affiliation
      else
        finals << affiliation
      end
    end
  end

  # Make unique and get counts
  unknowns.uniq!
  ranges.uniq!
  finals.uniq!
  nU = unknowns.length
  nR = ranges.length
  nF = finals.length

  # Normalize Unknowns
  if nU >= 1
    unknowns = ['(Unknown)']
    nU = 1
  end

  # Check number of finals
  if nF == 0
    if nU == 0
      # we have no unknown and no final
      if nR == 0
        # no ranges
        puts "#{key}: wrong affiliations: #{affiliations} - no final, no unknown, no ranges" if verbose
        exit 1
      else
        # we have ranges
        puts "#{key}: wrong affiliations: #{affiliations} - no final, no unknown, ranges present" if verbose
        exit 1
      end
    else
      # We have 1 unknown and no final
      if nR == 0
        # only unknown
        return unknowns.first
      else
        # 1 unknown, no final and ranges
        puts "#{key}: wrong affiliations: #{affiliations} - no final, unknown, ranges present" if verbose
        exit 1
      end
    end
  else
    # > 0 final values
    if nF > 1
      if guess
        # More than 1 final value
        fin = finals.first
        finals.each do |final|
          if fin == 'Independent' && final != 'Independent'
            fin = final
            break
          end
        end
        puts "#{key}: wrong affiliations: #{affiliations} - multiple final affiliations, picked: #{fin}" if verbose
        finals = [fin]
      else
        puts "#{key}: wrong affiliations: #{affiliations} - multiple final affiliations, treating as unknown" if verbose
        return '(Unknown)'
      end
    end
    # we have final, if there is also unknown - skip it
    if nR == 0
      # no ranges, final value
      return finals.first
    else
      # ranges and final, no unknowns
      return (ranges + finals).join ', '
    end
  end
end

def merge_multiple_logins(data, verbose)
  profs = {}
  data.each_with_index do |user, i|
    login = user['login']
    profs[login] = [] unless profs.key?(login)
    profs[login] << [user, i]
  end
  mp = {}
  profs.each do |login, profiles|
    mp[login] = profiles if profiles.length > 1
  end
  profs = nil
  mp.each do |login, profiles|
    unknowns = []
    knowns = []
    profiles.each do |profile_data|
      profile, i = *profile_data
      affiliation = profile['affiliation']
      if ['?', 'NotFound', '(Unknown)'].include?(affiliation)
        unknowns << [profile, i]
      else
        knowns << [profile, i]
      end
    end
    if unknowns.length > 0 and knowns.length > 0
      aff = knowns.first[0]['affiliation']
      conflict = false
      knowns.each do |profile_data|
        profile, i = *profile_data
        curr_aff = profile['affiliation']
        unless curr_aff == aff
          email = knowns.first[0]['email']
          curr_email = profile['email']
          source = knowns.first[0]['source']
          curr_source = profile['source']
          STDERR.puts "Affiliations conflict: login: #{login} #{email}:#{aff}(#{source}) != #{curr_email}:#{curr_aff}(#{curr_source})"
          conflict = true
        end
      end
      next if conflict
      unknowns.each do |profile_data|
        profile, i = *profile_data
        data[i]['affiliation'] = aff
        email = profile['email']
        if verbose && aff
          aff.split(', ').each do |aff_line|
            puts "#{email} #{aff_line}"
          end
        end
      end
    end
  end
end
