#!/usr/bin/python3

import requests
import sys
import time
import calendar
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

indice = 0
proxyList = []
urlTestProxy = "http://icanhazip.com"
list_proxy = []
proxiesList = []


def validation():
	global proxyList
	# typ = http, https, socks4, socks5
	typ = input ("Introduce tipo de proxy: http, https, socks4 o socks5 --> ")
	#typ = "socks5"
	# anon = transparent, anonymous, elite
	anon = input ("Introduce modo de proxy: transparent, anonymous o elite --> ")
	#anon = "elite"
	# country = Country ISO code
	country = input ("Introuce el código ISO del pais o déjalo vacio para seleccionar todas las opciones --> ")
	#country = "US"
	(proxies, statusProx) = getListProxy(typ, anon, country)
	if(statusProx == 200 and proxies):
		#proxiesList = proxies.split('\n')
		proxiesList = proxies.strip().split('\n')
		for p in proxiesList:
			proxyList.append(typ.strip() + "://" + p.strip())
			print(p)
		proxy = setProxy()
			

def getListProxy(typ, anon, country):
    url = "https://www.proxy-list.download/api/v1/get?type="+typ
    if(anon):
        url += "&anon="+anon
    if(country):
        url += "&country="+country

    res = requests.get(url)
    return res.text, res.status_code

def setProxy():
	global indice
	global proxyList

	for proxy_array in proxyList:
		print("\n" + proxy_array)
		if (testProxy(proxy_array)):
			list_proxy.append(proxy_array)

def testProxy(proxy):

	global urlTestProxy
	proxies = dict(http=proxy,https=proxy)
	try:
		print("[+] Obtaining Proxy to play...")
		r = requests.get(urlTestProxy, proxies=proxies, timeout=5)

		print("\t[*] Response: " + r.text.strip())
		if(r.text.strip() == proxy.split("://")[1].split(":")[0]):
			print("\t[*] Proxy Correct! Lets Play!")
			return True
		else:
			print("[-] Proxy Error! Find Another one!")
			return False
	except requests.exceptions.Timeout:
		print("[-] Proxy Error Timeout! Find Another one!")
		return False
	except requests.exceptions.ConnectionError:
		print("[-] Proxy Error Conection Error! Find Another one!")
		return False
	except Exception as e:
		print("Error: " + str(e))
		print("[-] Proxy Error! Find Another one!")
		return False

def main():
	validation()
	current_GMT = time.gmtime()
	time_stamp = str(calendar.timegm(current_GMT))
	name = time_stamp + "-List_Proxies_working"
	results = open(name, 'w+')
	for proxy in list_proxy:
		print("Proxies funcionando son: "+proxy)
		results.write(proxy + "\n")
	results.close()

if __name__ == '__main__':
	main()
