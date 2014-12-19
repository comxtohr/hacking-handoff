import socket


list = ['1','12','1234','5']
for i in list:
	c = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
	c.connect(('172.16.132.138',9999))
	c.send(i)
	c.close()
