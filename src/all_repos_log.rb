#!/usr/bin/env ruby

require 'etc'
require 'timeout'
require 'pry'

def generate_logs(repos)
  ts = Time.now
  log = 'git.log'
  dbg = !ENV['DBG'].nil?
  silent = !ENV['SILENT'].nil?
  pwd = `pwd`.strip!
  maxProc = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
  pids = []
  pdata = {}
  failed = {}
  timeout_bool = !ENV['TIMEOUT'].nil?
  if timeout_bool
    timeout_seconds = ENV['TIMEOUT'].to_i
  else
    timeout_seconds = 3600
  end
  n_repos = repos.length
  repos.each_with_index do |repo, idx|
    puts "#{idx}/#{n_repos}" if !silent && idx > 0 && idx%10 == 0
    fnr="#{pwd}/git_logs/#{repo.gsub('/', '_')}"
    lfn="#{fnr}.log"
    fn1="#{fnr}.1"
    fn2="#{fnr}.2"
    pid = fork do
      p = Process.pid
      t1 = Time.now
      cmd = "./repo_log.sh '#{repo}'"
      res = `#{cmd}`
      rcode = $?.exitstatus
      t2 = Time.now
      tm = t2 - t1
      puts "Time '#{cmd}': #{tm}" if dbg
      unless silent || rcode.zero?
        puts "Command PID: #{p}, '#{cmd}', retuned error code #{rcode}, time: #{tm}, see: #{fnr}"
        o1 = `cat "#{fn1}"`.strip!
        o2 = `cat "#{fn2}"`.strip!
        puts "Command PID: #{p}, '#{cmd}' stdout: '#{o1}'" if o1 && o1.length > 0
        puts "Command PID: #{p}, '#{cmd}' stderr: '#{o2}'" if o2 && o2.length > 0
      end
      exit rcode
    end
    pids << pid
    pdata[pid] = lfn
    if pids.count >= maxProc
      pid = pids[0]
      pids = pids[1..-1]
      t1 = Time.now
      begin
        Timeout::timeout(timeout_seconds) do
        Process.wait pid
        rcode = $?.exitstatus
        unless rcode.zero?
          puts "PID #{pid}, exit: #{rcode}" unless silent
          failed[pid] = [rcode, pdata.delete(pid)]
        end
      end
      rescue Timeout::Error
        t2 = Time.now
        tm = t2 - t1
        puts "Timeout PID #{pid}, after #{tm}"
        Process.kill('KILL', pid)
        failed[pid] = [0, pdata.delete(pid)]
      end
    end
  end
  pids.each do |pid|
    t1 = Time.now
    begin
      Timeout::timeout(timeout_seconds) do
        Process.wait pid
        rcode = $?.exitstatus
        unless rcode.zero?
          puts "PID #{pid}, exit: #{rcode}" unless silent
          failed[pid] = [rcode, pdata.delete(pid)]
        end
      end
    rescue Timeout::Error
      t2 = Time.now
      tm = t2 - t1
      puts "Timeout PID #{pid}, after #{tm}"
      Process.kill('KILL', pid)
      failed[pid] = [0, pdata.delete(pid)]
    end
  end
  puts "Failed: #{failed.length}" if failed.length > 0
  failed.each do |pid, data|
    code = data[0]
    lfn = data[1]
    if code.zero?
      puts "Timeout PID #{pid}: #{lfn}"
    else
      puts "Error #{code} PID #{pid}: #{lfn}"
    end
  end
  puts "Merging #{pdata.length} logs"
  res = `> "#{log}"`
  rcode = $?.exitstatus
  unless rcode.zero?
    puts "Error #{rcode} for '#{cmd}': '#{res}'"
  end
  sums = {}
  pdata.each do |pid, lfn|
    sum = `md5sum '#{lfn}'`.split
    next if sum.length > 0 && sums.key?(sum[0])
    sums[sum[0]] = true
    cmd = "cat '#{lfn}' >> '#{log}'"
    res = `#{cmd}`
    rcode = $?.exitstatus
    unless rcode.zero?
      puts "Error #{rcode} for '#{cmd}': '#{res}'"
    end
  end
  # final stats
  te = Time.now
  tm = te - ts
  puts "All generated, time: #{tm}"
end

generate_logs ARGV
