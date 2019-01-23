require 'csv'
require 'pry'
require './email_code'

def aff(fn, email_col, date_col, affliation_col)
  # "Name","Email","Affliation","Date","Added","Removed","Changesets"
  # Project name,Repo Path,Repo Name,Author Date,Author Name,Author Email,Author Affiliation,Committer Date,Committer Name,Committer Email,Committer Affiliation,LoC Added,LoC Removed,Whitespace changes,Commit,Filename
  end_date_col = 'End Date'
  final_company_col = 'Last Affiliation'
  aff = {}
  CSV.foreach(fn, headers: true) do |row|
    h = row.to_h
    h.each do |k, v|
      h[k] = v.to_i if v.to_i.to_s == v
    end
    e = h[email_col]
    d = h[date_col]
    co = h[affliation_col].to_s
    if aff.key?(e) && aff[e].key?(d)
      if aff[e][d][affliation_col] != co
        puts "Affiliation mismatch (#{aff[e][d][affliation_col]} != #{co}) email: #{e}, date: #{d}, existing row:"
        puts aff[e][d]
        puts "New row:"
        puts h
      end
      aff[e][d].each do |k, v|
        aff[e][d][k] += h[k] unless v.is_a?(String) || !v || h[k].is_a?(String) || !h[k]
      end
    else
      aff[e] = {} unless aff.key?(e)
      aff[e][d] = h.clone
    end
  end

  aff_final = {}
  aff.each do |email, data|
    devs = data.keys.map { |d| [Date.parse(d), data[d]] }.sort_by { |row| row[0] }
    comps = devs.map { |r| r[1][affliation_col] }.uniq
    final_company = comps.last
    comps.each_with_index do |company, index|
      next_company = comps[index + 1]
      contributions = devs.select { |dev| dev[1][affliation_col] == company }.map { |c| c[1] }
      dt = contributions.first[date_col]
      if next_company
        dt2 = devs.select { |dev| dev[1][affliation_col] == next_company }.first[1][date_col]
      else
        dt2 = nil
      end
      contributions.each do |contrib|
        aff_final[email] = {} unless aff_final.key?(email)
        if aff_final[email].key?(dt)
          aff_final[email][dt].each do |k, v|
            aff_final[email][dt][k] += contrib[k] unless v.is_a?(String) || !v || contrib[k].is_a?(String) || !contrib[k]
          end
        else
          aff_final[email][dt] = contrib.clone
          aff_final[email][dt][end_date_col] = dt2 || ''
          aff_final[email][dt][final_company_col] = final_company
        end
      end
    end
  end

  # email,company,final_company,date_from,date_to
  hdr = %w(email company final_company date_from date_to)
  CSV.open('affs.csv', 'w', headers: hdr) do |csv|
    csv << hdr
    aff_final.keys.sort.each do |email|
      obj = aff_final[email]
      obj.keys.sort.each do |date|
        row = obj[date]
        csv << [email_encode(row[email_col]), row[final_company_col], row[affliation_col], row[date_col], row[end_date_col]]
      end
    end
  end
end

if ARGV.size < 4
  puts "Missing argument: devs_csv_file.csv email_col_name date_col_name affliation_col_name"
  exit(1)
end

aff(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
