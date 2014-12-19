import socket
import time
s = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
s.bind(("169.254.103.17",9999))
buf = ""
while True:
  data,addr = s.recvfrom(9999)
  print data
  with open('/Users/carl/Desktop/c.vcf','a') as file:
    file.write(data)
s.close()
print buf
print "connection closed"