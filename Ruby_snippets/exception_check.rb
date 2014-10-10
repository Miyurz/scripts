#!/usr/bin/ruby

begin
  $num1 = Integer(ARGV[0]) 
  $num2 = Integer(ARGV[1])
rescue Exception=>e1
  puts "Exception: "+e1
  #exit 1 
end

begin
  $calc = $num1 * $num2
  puts $calc
rescue Exception => e2
  puts "Exception: " +e2
  exit 2
end

