#!/usr/bin/ruby

puts "Menu"
puts "1.While Loop"
puts "2.Begin-While Loop"
puts "3.Until Loop"
puts "4.Until-While Loop"
puts "5.For loop"

condition = Integer(gets.chomp)

case condition

 when 1
    $i = 0
    $num = 5

    while $i < $num  do
       puts ("Inside the loop i = #$i" )
       $i +=1
    end

 when 2
    $i = 7
    $num = 5

    begin
       puts("Inside the loop i = #$i" )
       $i +=1
    end while $i < $num

 when 3
    $i = 4
    $num = 5

    until $i > $num  do
        puts("Inside the loop i = #$i" )
        $i +=1;
    end

 when 4
    $i = 10
    $num = 5
    begin
      puts("Inside the loop i = #$i" )
      $i +=1;
    end until $i > $num

 when 5
    for i in 10..15
       puts "Value of local variable is #{i}"
    end
  
 else
    puts "Unknown option!"

end
