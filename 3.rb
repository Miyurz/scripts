#!/usr/bin/ruby

require 'digest'

def encryption(encryptionType="MD5",stringToBeEncrypted="message")

puts "Encryption Type passed: #{encryptionType}"
puts "Encrypting string: #{stringToBeEncrypted}"

  case encryptionType
  when "SHA256"
    puts "Encrypting #{stringToBeEncrypted} with SHA256 algorithm"
    puts Digest::SHA256.digest '#{stringToBeEncrypted}'
  when "MD5"
    puts "Encrypting #{stringToBeEncrypted} with MD5 algorithm"
    puts Digest::MD5.hexdigest '#{stringToBeEncrypted}'
  else
    puts "UNKNOWN : Encrypting with unknown algorithm"
  end

end

arg1 = ARGV[0]
arg2 = ARGV[1]

encryption "#{arg1}","#{arg2}"
#encryption "SHA","mayur"
