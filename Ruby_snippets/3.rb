#!/usr/bin/ruby

require 'digest'

def encryption(encryptionType="MD5",stringToBeEncrypted="message",salt="test")

puts "Encryption Type passed: #{encryptionType}"
puts "Encrypting string: #{stringToBeEncrypted}"

  case encryptionType
  when "SHA256"
    puts "Encrypting #{stringToBeEncrypted} with SHA256 algorithm"
    puts Digest::SHA256.digest '#{stringToBeEncrypted}'
  when "SHA384"
    puts "Encrypting #{stringToBeEncrypted} with SHA384 algorithm"
    puts Digest::SHA384.digest '#{stringToBeEncrypted}'
  when "SHA512"
    puts "Encrypting #{stringToBeEncrypted} with SHA512 algorithm"
    puts Digest::SHA512.digest '#{stringToBeEncrypted}'
  when "HMAC"
    puts "Encrypting #{stringToBeEncrypted} with HMAC algorithm and salt, #{salt}"
    puts Digest::HMAC.hexdigest("#{stringToBeEncrypted}", "#{salt}", Digest::SHA1)
    #puts Digest::HMAC.hexdigest '#{stringToBeEncrypted}'
  when "MD5"
    puts "Encrypting #{stringToBeEncrypted} with MD5 algorithm"
    puts Digest::MD5.hexdigest '#{stringToBeEncrypted}'
  else
    puts "UNKNOWN : Encrypting with unknown algorithm"
  end

end

encryption = ARGV[0]
string = ARGV[1]
#Third argument should be the salt that is needed by some like the HMAC keyed-hashing algorithm
saltPassed = ARGV[2]

encryption "#{encryption}","#{string}","#{saltPassed}"
#encryption "SHA","mayur"
