configFiles = ['./config/env.vagrant.sh', './config/env.local.sh']

 #    Read in env variables
 env = Hash.new
  
     configFiles.each do |f|
         next if !File.file?(f)
              File.open(f) do |fp|
         	  fp.each do |line|
         	     line.chomp!
         	     next if !(line.start_with?('export '))
         	     key, value = line.gsub("export ", "").split("=")
                     env[key] = Integer(value) rescue value
         	     #puts "key: #{key} value: #{env[key]}"
                  end
              end
     end

     puts "Printing the env array(Hash)"
     #env.each_with_index {|val, index| puts "#{val} => #{index}" }
     
     env.each do |key, value|
          puts "key : #{key}, value: #{value}"
     end
