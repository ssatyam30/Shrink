#!/usr/bin/python

# Print the requests from HTTP method POST and collect address info in CSV
from BaseHTTPServer import HTTPServer, BaseHTTPRequestHandler
from optparse import OptionParser

import sys
import csv 
import requests 
import xml.etree.ElementTree as ET 
from xml.dom import minidom
import threading

#CSV File name where all the XML info will be saved
CSVFile = "psap_HTTP_requests.csv"
add_headers = 0
#default listning port for PSAP
port_no = 40001
CAS_SERVER_URL = "http://10.32.18.198:8080/"
PSAP_ID = "satya"
PSAP_PWD = "password"

class RequestHandler(BaseHTTPRequestHandler):
    

    def do_POST(self):
#        self.encoding = 'utf-8' 
        request_path = self.path
#	print(self.text)        
        print("\n----- Request Start ----->\n\n\n")
#        print(request_path)
#	print("request_path done")        
        request_headers = self.headers
        content_length = request_headers.getheaders('content-length')
        length = int(content_length[0]) if content_length else 0

        print("Request Path: "+request_path)
	a = check_headers(request_headers)
	#adding request path to dictionary a
	a["path"] = request_path

	xml_data = self.rfile.read(length)
#	xml_data.encoding = 'utf-8'
        check_xml_info(a, xml_data)
#	check_xml_info(a, self.rfile.read(length))

        self.send_response(200)
        self.send_header("Content-type", "text/xml; charset=\"UTF-8\"")    
        self.send_header("Connection", "close")
        print("<----- Request End -----\n\n\n")

    def do_GET(self):

        request_headers = self.headers

	content_length = request_headers.getheaders('content-length')
        length = int(content_length[0]) if content_length else 0
	get_message = self.rfile.read(length)

	#checking get message, if message = QUERY, sending POST query to CAS, or if message = shutdown, SHUTDOWN the server

	if get_message == "":
		message = "did not understand message"
		self.send_response(200)
		self.send_header('Content-type','text/html')
		self.end_headers()
		self.wfile.write(message)
	elif get_message == "SHUTDOWN":
		message = "shutting down server"
		self.send_response(200)
		self.send_header('Content-type','text/html')
		self.end_headers()
		self.wfile.write(message)
		shut_down_server()
	else:
		message = "Sending POST QUERY to CAS"
		self.send_response(200)
		self.send_header('Content-type','text/html')
		self.end_headers()
		self.wfile.write(message)
		send_POST(get_message)


def send_POST(msg):

        global CAS_SERVER_URL
        global PSAP_PWD
	global PSAP_PWD
	xml = """<?xml version="1.0"?><!DOCTYPE ip_svc_result SYSTEM "IP_SVC_RESULT_100.DTD"><ip_svc_result ver="1.0.0"><hdr ver="1.0.0"><client><id>"""+PSAP_ID+"""</id><pwd>"""+PSAP_PWD+"""</pwd></client></hdr><ip_rep ver="1.0.0"><repo><repo_tele>"""+msg+"""</repo_tele></repo></ip_rep></ip_svc_result>"""

#	headers = {'Content-Type': 'application/xml'} # set what your server accepts
	headers = {'Content-Type': 'text/xml; charset="UTF-8"', 'Date': 'Thu, 07 Jun 2018 12:49:20 GMT', 'User-Agent': 'Emergency', 'Connection': 'Close', 'Host': '10.32.9.62', 'Accept-Encoding': 'identity'} 

	url = CAS_SERVER_URL+"LocatonQueryServce/IPReq"
	print requests.post(url, data=xml, headers=headers).text



def check_headers(headers):

	# empty news dictionary 
	a = {}

#	expected_headers = ["User-Agent", "Accept", "Content-Type", "Date", "Connection", "X-OperatorId", "X-OperatorPassword", "Host" ]
	expected_headers = ["user-agent", "accept", "content-type", "date", "connection", "x-operatorId", "x-operatorPassword", "host" ]
	#User-Agent: curl/7.29.0
	#Accept: */*
	#Content-Type: text/xml;charset=UTF-8
	#Date: 7 Jun 2018 12:49:20 GMT
	#Connection: Close
	#X-OperatorId: Attachment xxxxxxxxxxxxx
	#X-OperatorPassword: Attachment xxxxxxxxxxxxxx
	#Host: 1.1.1.1
	#Content-Length: 495

	#check all the headers are received or not

	for h in expected_headers:
		try:
#			print("\nChecking header: "+h)
			print(h+" - \t\t received, value = "+headers[h])
#			a[h] = headers[h]
			a[h] = headers[h].replace(",", "")
		except:
			print(h+" NOT received ***** \n")

#        for a in headers:
#                print("header "+a+"\n")
#		print("value is"+headers[a]+"\n")
	return a

def check_xml_info(a, xmlInfo):
 
        ip_svc_result = ET.fromstring(xmlInfo)
	# create empty list for  tags and values
	values = [] 

        #getting repo_tel
	try:
		print("repo_tel: \t"+ip_svc_result[0][0][0].text.encode('utf8'))
		a[ip_svc_result[0][0][0].tag] = ip_svc_result[0][0][0].text.encode('utf8')
	except:
		print("did not receive repo_tel in xml data\n")
        #getting add_code
	try:
	        print("add_code: \t"+ip_svc_result[0][0][1][0][0].text.encode('utf8'))
		a[ip_svc_result[0][0][1][0][0].tag] = ip_svc_result[0][0][1][0][0].text.encode('utf8')
	except:
		print("did not receive add_code in xml data\n")
        #getting add_name
	try:
		print("add_name: \t"+ip_svc_result[0][0][1][0][1].text.encode('utf8'))
		a[ip_svc_result[0][0][1][0][1].tag] = ip_svc_result[0][0][1][0][1].text.encode('utf8')
	except:
		print("did not receive add_name in xml data\n")
        #getting add_num
	try:
	        print("add_num: \t"+ip_svc_result[0][0][1][0][2].text.encode('utf8'))
		a[ip_svc_result[0][0][1][0][2].tag] = ip_svc_result[0][0][1][0][2].text.encode('utf8')
	except:
		print("did not receive add_num in xml data\n")
        #getting others
	try:
		print("others: \t"+ip_svc_result[0][0][1][0][3].text.encode('utf8'))
		a[ip_svc_result[0][0][1][0][3].tag] = ip_svc_result[0][0][1][0][3].text.encode('utf8')
	except:
		print("did not receive others in xml data\n")
        #getting name_kana
	try:
	        print("name_kana: \t"+ip_svc_result[0][0][1][1][0].text.encode('utf8'))
		a[ip_svc_result[0][0][1][1][0].tag] = ip_svc_result[0][0][1][1][0].text.encode('utf8')
	except:
		print("did not receive name_kana in xml data\n")
        #getting name_kanji
	try:
		print("name_kanji: \t"+ip_svc_result[0][0][1][1][1].text.encode('utf8'))
		a[ip_svc_result[0][0][1][1][1].tag] = ip_svc_result[0][0][1][1][1].text.encode('utf8')
	except:
		print("did not receive name_kanji in xml data\n")

	values.append(a)
	# return news items list 
	save_to_CSV(values)
 
  
def save_to_CSV(data): 
 
    global add_headers
 
    # specifying the fields for csv file 
#    fields = ['path', 'user-agent', 'accept', 'content-type', 'date', 'connection', 'x-operatorId', 'x-operatorPassword', 'host', 'repo_tele', 'add_code', 'add_name', 'add_num', 'add_others', 'name_kana', 'name_kanji'] 
    fields = ['repo_tele', 'add_code', 'add_name', 'add_num', 'add_others', 'name_kana', 'name_kanji', 'path', 'user-agent', 'accept', 'content-type', 'date', 'connection', 'x-operatorId', 'x-operatorPassword', 'host']
    # writing to csv file, opening in append mode
    with open(CSVFile, 'a+') as csvfile: 
  
        # creating a csv dict writer object 
        writer = csv.DictWriter(csvfile, fieldnames = fields)
  
        # writing headers (field names) 
        if add_headers == 0:
		writer.writeheader()
		add_headers = 1
  
        # writing data rows 
        writer.writerows(data) 

def shut_down_server():

	# return response and shutdown the server
	assassin = threading.Thread(target=server.shutdown)
	assassin.daemon = True
	assassin.start()

      
#def main():
#	try:
#	    port = 40001
#	    print('Listening on localhost:%s' % port)
#	    server = HTTPServer(('', port), RequestHandler)
#	    server.serve_forever()
#	except KeyboardInterrupt:
#		print '^C received, shutting down the web server'
#		server.socket.close()
        
#if __name__ == "__main__":
#    parser = OptionParser()
#    parser.usage = ("Creates an http-server that will capture any POST parameters\n"
#                    "Run:\n\n"
#                    "   reflect")
#    (options, args) = parser.parse_args()
    
#    main()
     
try:
    port = int(sys.argv[1]) if sys.argv[1] else port_no
    CAS_SERVER_URL = sys.argv[2] if sys.argv[2] else CAS_SERVER_URL 
    PSAP_ID = sys.argv[3] if sys.argv[3] else PSAP_ID 
    PSAP_PWD = sys.argv[4] if sys.argv[4] else PSAP_PWD 
    CSVFile = sys.argv[5] if sys.argv[5] else CSVFile  
    print('Listening on localhost:%s' % port)
    server = HTTPServer(('', port), RequestHandler)
    server.serve_forever()
except KeyboardInterrupt:
    print '^C received, shutting down the web server'
    server.socket.close()

 
