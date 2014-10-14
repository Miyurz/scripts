#!/usr/bin/ruby

# Read more @ http://blog.rubybestpractices.com/posts/rklemme/003-The_Universe_between_begin_and_end.html

begin
  $num1 = Integer(ARGV[0]) 
  $num2 = Integer(ARGV[1])
rescue Exception=>e1
  puts "Exception: "+e1
  exit 1 
end

begin
  $calc = $num1 % $num2
  puts $calc
rescue Exception => e2
  puts "Exception encountered: " +e2
  puts e2.backtrace.inspect
  #puts "Performing mitigation actions."
  #raise e2
else
  puts "No errors! Congrats"
ensure
  puts "I will always execute!"
end

