import socket

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.bind(("172.16.132.138",9999))
s.listen(10)

while True:
  cs,ca = s.accept()
  print ca
  while True:
    data = cs.recv(500000)
    print data
    if not data: break
  cs.close()
  print "connection closed"
