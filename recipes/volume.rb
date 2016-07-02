read_cmd = "sudo -u #{node['sprout']['user']} defaults read com.apple.systemuiserver menuExtras"
old_menu_extras_cmd = Mixlib::ShellOut.new(read_cmd)
old_menu_extras_cmd.run_command
old_menu_extras = old_menu_extras_cmd.stdout

new_menu_extras = old_menu_extras.split("\n").select { |line| line !~ /Volume.menu/ }.insert(1,'"/System/Library/CoreServices/Menu Extras/Volume.menu",').join("\n")

execute 'Volume should appear in the status bar' do
  command "defaults write com.apple.systemuiserver menuExtras \'#{new_menu_extras}\'"
  user node['sprout']['user']
  only_if { new_menu_extras != old_menu_extras }
  notifies :run, 'execute[restart SystemUIServer]'
end

execute 'restart SystemUIServer' do
  command 'killall -HUP SystemUIServer'
  action :nothing
  ignore_failure true # SystemUIServer is not running if not logged in
end

execute "make sure it exists" do
  command 'defaults read com.apple.systemuiserver menuExtras | grep Volume.menu'
  user node['sprout']['user']
end
