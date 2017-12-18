require 'csv'
require 'pry'

def filestats(csv_file, out_file)
  puts "Running on #{csv_file}"
  # "email","name","date","affiliation","file","added","removed"
  comps = {}
  fcommits = fchanged = 0
  files = {}
  CSV.foreach(csv_file, headers: true) do |row|
    h = row.to_h
    c = h['affiliation']
    f = '/' + h['file']
    a = h['added'].to_i
    r = h['removed'].to_i
    mx = h['changed'].to_i
    files[f] = true
    # p [f, a, r, mx] if f.include?('/vendor')
    next if mx == 0
    # Use end index `-2` to parse only directories, use `-1` to parse files as well
    #ds = f.split('/')[0..-2]
    ds = f.split('/')[0..-1]
    dl = []
    l = ds.length - 1
    (0..l).each do |i|
      d = ds[0..i].join('/')
      dl << [d, d.count('/')]
    end
    comps[c] = {} unless comps.key?(c)
    comps[c][f] = [0, 0, 0, 0] unless comps[c].key?(f)
    comps[c][f][0] += a
    comps[c][f][1] += r
    comps[c][f][2] += mx
    comps[c][f][3] += 1
    dl.each do |dir|
      d = dir[0]
      l = dir[1]
      comps[c][l] = {} unless comps[c].key?(l)
      comps[c][l][d] = [0, 0, 0, 0] unless comps[c][l].key?(d)
      comps[c][l][d][0] += a
      comps[c][l][d][1] += r
      comps[c][l][d][2] += mx
      comps[c][l][d][3] += 1
    end
    fcommits += 1
    fchanged += mx
  end
  files = files.keys.sort

  # Summaries all & per company
  srt = []
  summary_all = [0, 0, 0, 0]
  summary_all2 = [0, 0, 0, 0]
  comps.each do |comp, data|
    changed = data[0][''][2]
    commits = data[0][''][3]
    srt << [comp, changed, commits]
    data[0][''].each_with_index do |value, index|
      summary_all[index] += value
    end
    # To check if algorithm is OK compare summary_all with summary_all2
    ks = data.keys.select { |k| k.is_a?(String) }
    ks.each do |k|
      d = data[k]
      d.each_with_index do |value, index|
        summary_all2[index] += value
      end
    end
  end
  binding.pry unless summary_all == summary_all2 && summary_all[2] == fchanged && summary_all[3] == fcommits
  summary_all = summary_all.map(&:to_f)

  # Top changed per lines modified and commits
  top_changed = srt.sort_by { |row| -row[1] }[0..14].map { |row| row[0] }
  top_commits = srt.sort_by { |row| -row[2] }[0..14].map { |row| row[0] }
  srt = []

  # Special cases that should always be included (if present)
  specials = ['Independent', 'NotFound', '(Unknown)'].each do |special|
    top_changed << special unless top_changed.include?(special)
    top_commits << special unless top_commits.include?(special)
  end

  # Analysis
  all_results = []
  [[top_changed, 'By changed lines', 2], [top_commits, 'By number of commits to file', 3]].each do |data|
    arr, order_name, v_index = data[0], data[1], data[2]
    all_results << ["All #{order_name}", 'All', 0, 0, '', summary_all[v_index].to_i, 100.0, 100.0]
    arr.each_with_index do |comp_name, c_index|
      c_index = c_index + 1
      comp = comps[comp_name]
      next unless comp
      summary = comp[0][''][v_index].to_f
      all_value = summary_all[v_index]
      summary_perc = ((summary * 100.0) / all_value).round(3)
      srt = []
      (1..20).each do |depth|
        next unless comp[depth]
        comp[depth].each do |dir, values|
          v = values[v_index].to_f
          vp = (100.0 * v / summary).round(3)
          vpa = (100.0 * v / all_value).round(3)
          srt << [order_name, comp_name, c_index, depth, dir[1..-1], v.to_i, vp, vpa]
        end
      end
      res = srt.sort_by { |row| -row[6] }.select.with_index { |row, r_index| row[6] > 1.0 && r_index < 25 }
      res = [["All #{order_name}", comp_name, c_index, 0, '', summary.to_i, summary_perc, summary_perc]] + res
      res.each { |rrow| all_results << rrow }
    end
  end

  # Remove duplicates - if changed only single file in directory(directories) path - then show only final file
  itocheck = [0, 1, 2, 4, 5]
  prev = [nil, nil, nil, nil]
  curr = [nil, nil, nil, nil]
  same = []
  final = []
  all_results.each_with_index do |res, index|
    itocheck.each_with_index do |ival, ii|
      curr[ii] = res[ival]
    end
    # Check if all non-string values (specified in itocheck) are the same and if one string is substring of another (3th in array)
    if all_substrings(curr, prev, 3)
      same << res
    else
      row = same.max_by { |r| r[3] }
      final << row if row
      same = [res]
    end
    prev = curr.dup
  end
  row = same.max_by { |r| r[3] }
  final << row if row
  all_results = nil

  hdr = %w(Order Company Index File/Directory Number Percent PercentAll)
  CSV.open(out_file, 'w', headers: hdr) do |csv|
    csv << hdr
    final.each { |i| csv << [i[0], i[1], i[2], i[4], i[5], i[6], i[7]] }
  end
  puts "Saved #{out_file}"
end

def all_substrings(arr1, arr2, sidx)
  s1 = ''
  s2 = ''
  arr1.each_with_index do |v1, i|
    v2 = arr2[i]
    if i == sidx
      s1 = v1
      s2 = v2
    else
      unless v1 == v2
        return false 
      end
    end
  end
  return s1.include?(s2) || s2.include?(s1)
end

if ARGV.size < 2
  puts "Missing arguments: in_file.csv out_file.csv (per_dirs/all.csv per_dirs/all_stats.csv)"
  exit(1)
end

filestats(ARGV[0], ARGV[1])
