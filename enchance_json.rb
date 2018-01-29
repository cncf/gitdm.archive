require 'pry'
require 'json'
require 'csv'
require 'octokit'
require './comment'
require './email_code'
require './ghapi'
require './merge'

def enchance_json(json_file, csv_file, actors_file)
  # This enables guessing if multiple final affiliations are given
  # Best option is to avoid this, by specifying exact affiliations everywhere!
  guess_by_email = true
  guess_by_name = false

  # Process actors file: it is a "," separated list of GitHub logins
  actors_data = File.read actors_file
  actors_array = actors_data.split(',').map(&:strip)
  actors = {}
  actors_array.each do |actor|
    actors[actor] = true
  end
  actors_array = actors_data = nil

  # Process affiliations found by Python cncf/gitdm saved in CSV
  # "email","name","company","date_to"
  email_affs = {}
  name_affs = {}
  names = {}
  emails = {}
  CSV.foreach(csv_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    e = email_encode(h['email'].strip)
    c = h['company'].strip
    n = h['name'].strip
    d = h['date_to'].strip

    # email -> names mapping (unique always, but dict just in case)
    names[e] = {} unless names.key?(e)
    names[e][n] = true

    # name --> emails mapping (one name can have multiple emails)
    emails[n] = {} unless emails.key?(n)
    emails[n][e] = true

    # affiliations by email
    email_affs[e] = [] unless email_affs.key?(e)
    if d && d.length > 0
      email_affs[e] << "#{c} < #{d}"
    else
      email_affs[e] << c
    end

    # affiliations by name
    name_affs[n] = [] unless name_affs.key?(n)
    if d && d.length > 0
      name_affs[n] << "#{c} < #{d}"
    else
      name_affs[n] << c
    end
  end

  # Make results as strings
  email_affs.each do |email, comps|
    email_affs[email] = check_affs_list email, comps, guess_by_email
  end
  name_affs.each do |name, comps|
    name_affs[name] = check_affs_list name, comps, guess_by_name
  end
  
  # Parse JSON
  data = JSON.parse File.read json_file

  # Enchance JSON
  n_users = data.count
  enchanced = csv_not_found = 0
  email_unks = []
  name_unks = []
  json_emails = {}
  known_logins = {}
  data.each do |user|
    e = email_encode(user['email'])
    n = user['name']
    l = user['login']
    known_logins[l] = true
    json_emails[e] = true
    v = '?'
    if email_affs.key?(e)
      # p [e, n, emails[n], names[e], email_affs[e], name_affs[n]]
      enchanced += 1
      v = email_affs[e]
    else
      if name_affs.key?(n)
        # p [e, n, emails[n], names[e], email_affs[e], name_affs[n]]
        enchanced += 1
        v = name_affs[n]
      else
        csv_not_found += 1
        email_unks << e
        name_unks << n
      end
    end
    user['affiliation'] = v
  end

  # Merge multiple logins
  merge_multiple_logins data, false

  skip_logins = {}
  skip_logins_arr = [
    # invalid
    '', nil,
    # bots
    'greenkeeper[bot]', 'web-flow', 'k8s-merge-robot', 'codecov[bot]', 'stale[bot]',
    # GitHub not founds
    '114piyush', '1gnition', '245347881', 'aaron12134', 'aaronLariat', 'abhinandanpb', 'abkaplan07', 'ablock84',
    'active-low', 'adv-tsk', 'agunnerson-explorys', 'ahmed-madkour', 'AleiHanami', 'alexraju', 'alibazaar',
    'ami-fairfly', 'amymotta24', 'andreagardiman', 'Aphoc', 'appledaily0', 'applequist', 'arash-bina', 'arduima',
    'arnaldopereira-luizalabs', 'Artie313', 'arvindt7', 'avmaximov', 'AwildStoltzAppears', 'bbnnt', 'beepee14',
    'beni05', 'bennyn1', 'benoit-merapar', 'bertrand-quenin', 'bharbhi', 'bigyouyou', 'bimalvv', 'bixiaohong2015',
    'bobymicroby', 'bporter2387', 'brant-cao', 'bruceherve', 'brunoqc', 'brunowoo', 'bryantly', 'BubacarrC',
    'canadatom', 'cgbspender', 'Chentongxuedefanhua', 'ChienWorld', 'chris-salemove', 'ChrJantz', 'c-kochu',
    'CliMz', 'cmpis', 'codecov[bot]', 'codefx9', 'colonelmo', 'conti-x-rob', 'DanielAIC', 'daniel-middleton',
    'danielscottt', 'darkhuwk', 'davey-dev', 'DBuTbKa', 'ddispaltro', 'Deepak-initcron', 'Demotivated',
    'dennis-bsi', 'dhart-alldigital', 'dirtGit', 'disneyworldguy', 'DivyaVavili', 'djmoky83', 'Docker-Image-Templates',
    'Dominic001', 'DougFirErickson', 'dw33z1lP', 'dyaniv', 'e-beach', 'ecnahc515', 'eddie-allen', 'electromecca',
    'elerion', 'elppc', 'emetchar', 'engine07', 'enigma99a', 'entropyfarms', 'epgrvp', 'epish', 'eric-tucker',
    'esthermofet', 'eulerzgy', 'evenemento', 'fangqiusheng', 'fen4o-work', 'fisch0920', 'flyat121', 'freshfishyu',
    'freshfrmthehood', 'Furtchet', 'futureskywei', 'gatoruso', 'gayanjay', 'gdscei', 'geekard', 'geetachauhan',
    'gegtot', 'gen0cide-', 'Gentlehag', 'gghonor', 'ghasabian', 'ghoffer', 'gitoverflow', 'gmarek-google',
    'GoatWalker', 'gravityjeff', 'greenkeeper[bot]', 'gregster85', 'guimelon', 'GuoHui89757', 'h0me', 'hallucynogenyc',
    'harish-myaccount', 'heavenlyhash', 'hecklerm', 'hfzqls', 'hitechmike', 'hobo-c', 'HuShuangFeng', 'iamthemuffinman',
    'im-di', 'inigo-montoyahh', 'invenfantasy', 'Irving23', 'isArbit', 'ITPro360', 'itsmrwave', 'iurii-polishchuk',
    'jamesberlage', 'JavierLorenzoPouso', 'jcastillo-cb', 'jcorral', 'jdc2172', 'Jeremysoft', 'jesstm',
    'jgriffiths1993', 'jhernandezme', 'JimTravisGoog', 'jinmiaoms', 'johnwchadwick', 'jrahn42', 'jtbcgdv',
    'JulienLenne', 'jvkisy', 'k8s-merge-robot', 'Kaffa-MY', 'kaustubhvp', 'keglevich3', 'keith4743', 'ket4yii',
    'king-julien', 'klaus1982', 'komposebot', 'konstantaroglou', 'koombea-rops', 'kostyrevaa', 'kramshoej',
    'KubernetesIntership', 'kwinczek', 'lcalcote', 'lcowdrey', 'lendico-dmitry-dzifuta', 'lhampe', 'life360-rops',
    'linuxpython', 'LittleStan', 'liust2014', 'lixiaobing10051267', 'lordxx', 'lorenzvth7', 'Luxurioust', 'lycoris0731',
    'm081072', 'mad0house', 'Manko10', 'markfejes', 'markpaychex', 'matesito', 'mattaitchison', 'mehra-ashu',
    'mengfanjiebay', 'mesmerizingr', 'mhrgoog', 'michael-endsley', 'mikudeko', 'mjbrender', 'mkibbe1993',
    'mmarcant', 'moon03432', 'morelena', 'mozzymoz', 'msowka-ninja', 'mynameismevin', 'n1tr0g', 'Nagodar', 'natostanco',
    'nelcy', 'nikitswaraj12345', 'ninkendo', 'nirving-versent', 'nitro3v', 'nivwusquorum', 'noam-fairfly', 'nohupz',
    'nstoggs', 'oamasood', 'obimod', 'ocsbrandon', 'ok-he', 'oMikeGo', 'OpenJoy', 'ouyanggh', 'pankajsaha',
    'paulomakdisse', 'paytinka', 'Pes2009k', 'PeterJausovec', 'phofmann-trust', 'pivotal-topher-bullock', 'pixlepix',
    'pl33g0r', 'pletisan', 'pnzrdrgoon', 'polariss0i', 'poonia0arun', 'psiclops', 'punitag', 'pylior', 'qms880124',
    'quackenbushman', 'quofelix', 'raeesbhatti', 'raeesiqbal', 'rajitha-wijayaratne', 'randollr', 'rashmimargani',
    'rastapopulous', 'reach123', 'redhatlinux10', 'rhohan', 'riazkarim', 'richardLuk', 'rifung', 'ripcurld00d',
    'robertchoi8099', 'robertnie', 'robin-opsguru', 'romlein', 'ronalexander', 'rsahai91', 'rsokolkov', 'runseb',
    'rvu95', 'ryaneleary', 'ryanp424', 'sachindj', 'sajjadmurtaza-ror', 'saksham0808', 'Scentus', 'scheng1', 'SebErrien',
    'sebknoth', 'seveillac', 'shepp67', 'sigmundlundgren', 'Simon-lush', 'sindbis', 'sindhuragarapati', 'sinzone',
    'sjl2024', 'slawiek', 'slouly', 's-miyoshi-fj', 'snowhigh', 'soiff', 'spartacus06', 'srzjulio', 'Stackle', 'stean93',
    'stefanbueringer', 'Steniaz', 'Steve53', 'stevenbrichards', 'stevenswong', 'sumsuddinshojib', 'sunfaces',
    'sungwookgit', 'swordphilic', 'SydOps', 'taotaotheripper', 'tavispaquette', 'TaylorLBJ', 'tech2free', 'thaerlo',
    'thatoldroad', 'thebeardisred', 'thebeefcake', 'thecanadianbaker', 'thedos1701', 'thenamli', 'theo01', 'thinhduckhoi',
    'thirunavukkarasumca', 'thourfor', 'tinkerdba', 'tmgardner', 'traviscox1990', 'umrigark', 'Usnarski', 'uvgroovy',
    'vasil-moneybird', 'veverjak', 'viruxel', 'volyihin', 'VsMaX', 'vteves-pf9', 'w00204372', 'wallverb', 'wangxfbelieve',
    'wenwenwenjun', 'winniwinter', 'WinstonSureChill', 'wo8113596', 'wolfador', 'woodbor', 'worldfirst1', 'xiangli-cmu',
    'xLegoz', 'XsWack', 'xylin821', 'yangguilei', 'YdnaRa', 'YingBurden', 'yjww', 'ymqytw', 'yoo2767', 'yoshuaalvin',
    'yslzsl', 'YuquanRen', 'yxu900331', 'Zapadlo', 'ZhangBanger', 'zhaoguoxin', 'zhaoxpZTE', 'zhi-feng', 'zine2hamster',
    'ZMI-JayGorrell', 'zyren88',
    '1810755jiawei', 'aaroncai-myob', 'Agrosis', 'Atlashugged', 'better88', 'bitbyteshort', 'blemagicleap', 'brdude',
    'Cedric-Venet', 'Doron-offir', 'DreamLog', 'dxarm', 'FlorianOnmyown', 'Gr1dd', 'guoliang88', 'jamesawebb1',
    'kargakis-bot', 'kavehmzta', 'kbrinnehl', 'klud1', 'leftyhitchens', 'lukaseichler', 'MaksymDev', 'markbarks',
    'MikaelCluseau', 'moravit', 'MurgaNikolay', 'prateek-1708', 'qhartman-t3', 'qwangrepos', 'shubhamchaudhary',
    'simonwydooghe', 'spacexnice', 'thecantero', 'will835559313', 'Yangsheng93', '240ch', 'aardestani', 'Achohr',
    'adityatalks', 'alin-sinpalean', 'AnudeepReddyJ21', 'a-pastushenko', 'applegrain', 'awsuderman', 'bellmounte',
    'bogdanbadescu', 'chrislonng', 'Christmas-shl', 'c-j-s', 'cpb83', 'cumulus-drew', 'DanGoldbach', 'devghai',
    'dopykuh', 'EverChris', 'EyesBear', 'fraserrj', 'GeorgeYuen', 'giaquinti', 'gittex', 'gsabena', 'hajzso', 'ih16',
    'jessebolson', 'linqianqiu', 'm247suppport', 'machinelady', 'mattharden', 'mlety2', 'MojojojoPowwa', 'mwitkow-io',
    'nirav7715', 'obsoleter', 'opensourcegrrrl', 'pkrupa2', 'pofuk', 'prettyxw', 'ProfessorYang', 'rihardsf',
    'rud-bookbites', 'ryanturner', 'ShalomCohen', 'shartmnn', 'srikanth789', 'szxnyc', 'Theci', 'TianleChew',
    'TomaszSekTesco', 'tom-tuddenham-bulletproof', 'u-c-l', 'unixhup', 'vinihi83', 'wombledmaize', 'yupeng820921',
    'zcytop', 'missionrulz', 'PSG-Luna', 'aeibrahim', 'allamiro1', 'Ankushaccc', 'AphexFX', 'arascanakin',
    'bbc-tomfitzhenry', 'bernie4321', 'chrischillibean', 'daic-h', 'darkdep', 'daveb0t', 'Hapa29', 'IamBc', 'joshcwa',
    'kazeula', 'lance-edmodo', 'lk432', 'niku4i', 'paintss', 'phaothu', 'Psyered', 'rdcastro', 'rgjkugiya', 'salty-g',
    'shoichikaji', 'sony-shinichi-hatayama', 'sriramflydata', 'takashibagura', 'tanaka51-jp', 'TeslaCtroitel', 'UijunLee',
    'ykitac', 'zhuoyikang', 'dario-simonetti', 'jtaylor32', 'maneeshvittolia', 'robbfoster', 'zhao141', '2050SXZ',
    'ananthonline', 'andela-gjames', 'andela-jmuli', 'andela-oadesanya', 'arthurcburigo', 'b1101', 'cblichmann-google',
    'ceoacai', 'chedeti', 'coconut73', 'contributor123', 'daschwanden', 'dasotong', 'DavidAudrain', 'davidclaridge',
    'davidmoravek', 'deja-v-u', 'devanshujain919', 'drbo', 'dsudia', 'elenabdecastro', 'Emmpa', 'fowlslegs',
    'frostymarvelous', 'giannisantinelli', 'goodsoldiersvejk', 'Grvs7', 'HugoSTorres', 'iamtiancaif', 'itamar-yowza',
    'jazzgal', 'j-slvr', 'juanpmarin-infocorp', 'kamidude', 'kangjoni76', 'killjason', 'krundrufanatics', 'lememora',
    'leonard-shi', 'leonard-sxy', 'leonliu333', 'linardo', 'liuempire', 'liuhanlcj', 'manjunathshetty', 'mastermix252',
    'mdhheydari', 'mewent', 'Mint-Zhao-Chiu', 'nuss-justin', 'onetwogoo', 'osDanielLee', 'PabloCariel', 'pocographdotcom',
    'PowerInside', 'prazzt', 'qxd666666', 'Randigtschackspel', 'rok987', 'ryanchou1991', 'sadeghis', 'slafgod000',
    'soccerlalo2', 'sofuckingnice', 'twoeo', 'ullutau', 'UnICorN21', 'userlocalhost2000', 'ustime', 'was4444',
    'WillSmithInChina', 'wizwjw', 'YoungyoungX', 'ysihaoy', 'yyannekk', 'zachizi', 'Zerqkboo', 'zhengzhuo2017',
    'zp-j', 'ijc25', 'jintingying', 'rneugeba', 'xianwei2016', 'OricanIs', 'TravisBurandt', 'vaantts', 'CoolaDani',
    'Durtdiver', 'xaxiclouddev', '412428728', 'msm93v2', 'ra90707', 'ssmnp', 'lzdlsmndy', 'HearingFish', 'tehscorpion',
    'Advil-Robin', 'bordeltabernacle', 'brookerj11211', 'castillobg', 'charliedrage', 'drumulonimbus', 'erikano',
    'fwilson42', 'justiniac', 'laurchris', 'meganuke19', 'mezcalero', 'pmatts', 'progrn', 'ramitsurana05',
    'talon-hartmann', 'virtualswede', 'zhq527725', 'Kdcm', 'akshayadatta', 'GeorgiKhomeriki', 'isaach1000',
    'MengZhi825', 'ZAntony', 'ali-yousuf-10p', 'mkonakan', 'mstanleyjones', 'Kwang100'
  ]
  skip_logins_arr.each { |skip_login| skip_logins[skip_login] = true }

  # Actors from cncf/devstats that are missing in our JSON
  unknown_actors = {}
  actors.keys.each do |actor|
    unknown_actors[actor] = true unless known_logins.key?(actor) || skip_logins.key?(actor)
  end
  puts "We are missing #{unknown_actors.keys.count} contributors from #{actors_file}"

  # Actors from out JSON that have no contributions in cncf/devstats
  unknown_logins = {}
  known_logins.keys.each do |login|
    unknown_logins[login] = true unless actors.key?(login)
  end
  puts "We have #{unknown_logins.keys.count} actors in our JSON not listed in #{actors_file}"

  actor_not_found = 0
  actors_found = 0
  if unknown_actors.keys.count > 0
    octokit_init()
    rate_limit()
    puts "We need to process additional actors using GitHub API, type exit-program if you want to exit"
    uacts = unknown_actors.keys
    n_users = uacts.size
    binding.pry
    uacts.each_with_index do |actor, index|
      begin
        rate_limit()
        e = "#{actor}!users.noreply.github.com"
        puts "Asking for #{index}/#{n_users}: GitHub: #{actor}, email: #{e}, found so far: #{actors_found}"
        u = Octokit.user actor
        login = u['login']
        n = u['name']
        u['email'] = e
        u['commits'] = 0
        v = '?'
        if email_affs.key?(e)
          p [e, n, emails[n], names[e], email_affs[e], name_affs[n]]
          actors_found += 1
          v = email_affs[e]
        else
          if name_affs.key?(n)
            p [e, n, emails[n], names[e], email_affs[e], name_affs[n]]
            actors_found += 1
            v = name_affs[n]
            e2 = emails[n].keys.first
            u['email'] = e2 unless e2 == e
          else
            actor_not_found += 1
          end
        end
        u['affiliation'] = v
        puts "Got name: #{u[:name] || u['name']}, login: #{u[:login] || u['login']}"
        h = u.to_h
        data << h
        if login != actor
          u2 = u.clone
          u2['login'] = actor
          h2 = u2.to_h
          data << h2
        end
      rescue Octokit::TooManyRequests => err
        td = rate_limit()
        puts "Too many GitHub requests, sleeping for #{td} seconds"
        sleep td
        retry
      rescue Octokit::NotFound => err
        puts "GitHub doesn't know actor #{actor}"
        puts err
      rescue => err
        puts "Uups, somethis bad happened, check `err` variable!"
        binding.pry
      end
    end
    puts "Found #{actors_found}, not found #{actor_not_found} from #{n_users} additional actors"
  end

  json_not_found = 0
  unks2 = []
  email_affs.each do |email, aff|
    next unless aff == '(Unknown)'
    unless json_emails.key?(email)
      json_not_found += 1
      unks2 << "#{email} #{names[email]}"
    end
  end
  puts "Processed #{n_users} users, enchanced: #{enchanced}, not found in CSV: #{csv_not_found}, unknowns not found in JSON: #{json_not_found}."
  # puts "Unknown emails from JSON not found in CSV (VIM search pattern):"
  # puts email_unks.join '\|'
  # puts "Unknown names from JSON not found in CSV (VIM search pattern):"
  # puts name_unks.join '\|'
  # puts "Unknown emails from CSV not found in JSON"
  # puts unks2.join("\n")
  # File.write 'not_found_in_json.txt', unks2.join("\n")

  # Write JSON back
  json = JSON.pretty_generate data
  File.write json_file, json
end

if ARGV.size < 3
    puts "Missing arguments: JSON_file CSV_file Actors_file (github_users.json all_affs.csv actors.txt)"
  exit(1)
end

enchance_json(ARGV[0], ARGV[1], ARGV[2])
