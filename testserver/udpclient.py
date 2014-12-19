import socket  

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  
s.sendto("Hello server!",("172.16.132.138",9999))  
s.close()  