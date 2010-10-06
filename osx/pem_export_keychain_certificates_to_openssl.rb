#!/usr/bin/ruby
require "open3"

# Script to export all certificates in OS X SystemRoots Keychain to OpenSSL
# readible certificates.
#   OS X ships with a full OpenSSL installation and it ships with public 
#   certificates from recognized CAs. The problem is that Unix applications 
#   compiled against the OpenSSL libraries cannot make use of those 
#   certificates. You’ll need to export them from the system keychain in order 
#   to make them available to those applications.
#   (quoted from http://www.madboa.com/geek/pine-macosx/#openssl)
#
# Reads certificates from /System/Library/Keychains/SystemRootCertificates.keychain
# and exports those certificates in pem format to /System/Library/OpenSSL/certs/
# Also runs c_rehash on the folder /System/Library/OpenSSL/certs/ to add 
# symbolic links to the hash values of the exported pem files.
#
# Usage:
#   sudo ruby pem_export_keychain_certificates_to_openssl.rb
#


# Run's a command and returns an hash with stdout and stderr
# return lines{:stdout => "...", :stderr => "..."}
def run_command(command)
  lines = Hash.new
  lines[:stdout] = ""
  lines[:stderr] = ""
  stdin, stdout, stderr = Open3.popen3(command)
  stdout.each {|line| lines[:stdout] << "#{line}" }
  stderr.each {|line| lines[:stderr] << "#{line}" }
  return lines
end

# Find all certificates in the SystemRoots Keychain
l = run_command("security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain")

# Create a .pem file in /System/Library/OpenSSL/certs/ for each certificate
i = 0
l[:stdout].each {|line|
  if line =~ /-----BEGIN CERTIFICATE-----\n/
    i += 1
    @f = File.new("/System/Library/OpenSSL/certs/#{i}.pem", "w+")
  end
  @f.puts line
  if line =~ /-----END CERTIFICATE-----\n/
    @f.close
  end
}
puts "#{i} certificates exported to /System/Library/OpenSSL/certs/"

# Rehash certificates
run_command("c_rehash /System/Library/OpenSSL/certs/")