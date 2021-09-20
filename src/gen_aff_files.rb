require 'csv'
require 'json'
require 'pry'
require './comment'
require './email_code'

def sort_and_add_dates(a)
  affs = a.split(',')
  l = affs.length
  sa = []
  affs.each do |aff|
    aff = aff.strip
    ary = aff.split('<')
    if ary.length == 1
      dt = '2100-01-01'
    else
      dt = ary[1].strip
    end
    c = ary[0].strip
    sa << dt + " < " + c
  end
  sa = sa.sort
  s = ''
  sa.each_with_index do |aff, i|
    ary = aff.split('<')
    binding.pry if ary.length != 2
    if i == 0
      dt = '1900-01-01'
    else
      prev = sa[i-1]
      ary2 = prev.split('<')
      binding.pry if ary2.length != 2
      dt = ary2[0].strip
    end
    s += dt + ' < ' + ary[1].strip + ' < ' + ary[0].strip
    if i < l - 1
      s += ', '
    end
  end
  # puts "#{a} -> #{s}"
  return s
end

def gen_aff_files(json_file)
  # Parse JSON
  puts "getting logins with affiliations..."
  data = JSON.parse File.read json_file
  logins = {}
  data.each do |row|
    h = row.to_h
    a = h['affiliation']
    next if a.nil? || a == '' || a == '?' || a == 'NotFound' || a == '(Unknown)'
    l = h['login']
    logins[l] = [] unless logins.key?(l)
    logins[l] << h
  end

  puts "processing affiliations data..."
  ldata = {}
  cdata = {}
  logins.each do |login, rows|
    affs = {}
    rows.each do |row|
      a = row['affiliation']
      e = row['email']
      affs[a] = [] unless affs.key?(a)
      affs[a] << e
    end
    affs2 = {}
    affs.each do |daff, emails|
      aff = sort_and_add_dates(daff)
      semails = emails.join(', ')
      affs2[aff] = semails
    end
    affs2.each do |aff, emails|
      arr = aff.split ','
      arr.each do |d|
        d = d.strip
        arr2 = d.split '<'
        l = arr2.length
        binding.pry if l != 3
        pdt = arr2[0].strip
        c = arr2[1].strip
        dt = arr2[2].strip
        cdata[c] = {} unless cdata.key?(c)
        cdata[c][login] = {} unless cdata[c].key?(login)
        cdata[c][login][emails] = [] unless cdata[c][login].key?(emails)
        cdata[c][login][emails] << [pdt, c, dt]
      end
    end
    ldata[login] = affs2
  end

  puts "generating developer affiliations file..."
  t = ''
  ldata.keys.sort.each do |login|
    data = ldata[login]
    m = {}
    data.each do |k, v|
      v2 = v.split(', ').sort.join(', ')
      m[v2] = k
    end
    m.keys.sort.each do |emails|
      affs = m[emails]
      t += login + ': ' + emails + "\n"
      affs.split(', ').each do |aff|
        ary = aff.split(' < ')
        binding.pry if ary.length != 3
        t += "\t" + ary[1]
        from = ary[0]
        t += ' from ' + from if from != '1900-01-01'
        to = ary[2]
        t += ' until ' + to if to != '2100-01-01'
        t += "\n"
      end
    end
  end
  hdr = "# This is the main developers affiliations file.\n"
  hdr += "# If you see your name with asterisk '*' sign - it means that\n"
  hdr += "# multiple affiliations were found for you with different email addresses.\n"
  hdr += "# Please merge all of them into one then.\n"
  hdr += "# Note that email addresses below are \"best effort\" and are out-of-date\n"
  hdr += "# or inaccurate in many cases. Please do not rely on this email information\n"
  hdr += "# without verification.\n"
  File.write '../developers_affiliations.txt', hdr + t

  t = ''
  cdata.keys.sort.each do |company|
    t += company + ":\n"
    data = cdata[company]
    data.keys.sort.each do |login|
      emd = data[login]
      m = {}
      emd.each do |k, v|
        k2 = k.split(', ').sort.join(', ')
        m[k2] = v
      end
      m.keys.sort.each do |emails|
        affs = m[emails]
        t += "\t" + login + ': ' + emails
        l = affs.length
        affs.each_with_index do |aff, i|
          s = ''
          from = aff[0]
          to = aff[2]
          binding.pry if aff[1] != company
          s += ' from ' + from if from != '1900-01-01'
          s += ' until ' + to if to != '2100-01-01'
          if s != ''
            t += s
            t += ',' if i < l - 1
          end
        end
        t += "\n"
      end
    end
  end
  hdr =  "# This file is derived from developers_affiliations.txt and so should not be edited directly.\n"
  hdr += "# If you see an error, please update developers_affiliations.txt and this file will be fixed\n"
  hdr += "# when regenerated.\n"
  File.write '../company_developers.txt', hdr + t
end

if ARGV.size < 1
  puts "Missing argument: json_file (github_users.json)"
  exit(1)
end

gen_aff_files(ARGV[0])
