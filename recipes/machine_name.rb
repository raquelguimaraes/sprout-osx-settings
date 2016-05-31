def hostname
  cmd = Mixlib::ShellOut('hostname')
  cmd.run_command
  cmd.stdout.chomp
end

def real_interfaces
  cmd = Mixlib::ShellOut('netstat -ni')
  cmd.run_command
  cmd.stdout.split("\n").select { |line| line.match(/en.*((\d+\.){3}\d+)/) }
end

def computer_name
  cmd = Mixlib::ShellOut('scutil --get ComputerName')
  cmd.run_command
  cmd.stdout.chomp
end

hostnames = [hostname]

require 'socket'
host_ips = real_interfaces.collect do |line|
  line =~ /en.*?((\d+\.){3}\d+)/
  Regexp.last_match(1)
end

host_ips.each do |ip|
  begin
    hostnames << Socket.gethostbyaddr(ip.split(/\./).collect!(&:to_i).pack('CCCC'))[0]
  rescue SocketError
    log "no reverse lookup for \"#{ip}\""
  end
end

hostnames.each do |hostname|
  log "My hostname: #{hostname}"
  next unless hostname =~ /#{node['machine_domain']}/ && hostname !~ /^dyn-/
  hostname = hostname.gsub(/\..*/, '')

  # The scutil commands need to run as root, unless
  # you're logged into the console, but we can't be sure of that.

  ["scutil --set ComputerName #{hostname}",
   "scutil --set LocalHostName #{hostname}",
   "scutil --set HostName #{hostname}",
   "hostname #{hostname}",
   "diskutil rename / #{hostname}"].each do |host_cmd|
    execute host_cmd
  end

  ruby_block 'test to see if hostname was set' do
    block do
      raise 'Setting of hostname failed' unless hostname == computer_name
    end
  end
end
