
import socket
import ssl
import hashlib
import subprocess
import threading
import time
import logging
import sys
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG, format="%(asctime)s: %(message)s", datefmt="%Y-%m-%d %H:%M:%S")

event_suffix_found = threading.Event()
result_suffix = b""

settings_linux_CPU_farm = [{"name" : "root", "ip" : "10.245.0.43", "pass": "xxx", "path": "/root/"},
       {"name" : "root", "ip" : "10.245.0.42", "pass": "xxx", "path": "/root/"},
       {"name" : "root", "ip" : "10.245.0.41", "pass": "xxx", "path": "/root/"},
       {"name" : "root", "ip" : "10.245.0.40", "pass": "xxx", "path": "/root/"}
       ]

def StopAllCPUFarm(): 
    for val in settings_linux_CPU_farm:
        subprocess.call("plink -pw {passw} {name}@{ip} pkill -f BruteForceSHA1CPU".format(
            passw=val["pass"],
            name=val["name"],
            ip=val["ip"]
            ), shell=True)
        subprocess.call("plink -pw {passw} {name}@{ip} \"ps aux | grep BruteForceSHA1CPU\"".format(
            passw=val["pass"],
            name=val["name"],
            ip=val["ip"]
            ), shell=True)

def UpdateAllCPUFarmWithNewVersion():
    for val in settings_linux_CPU_farm:
        subprocess.call("echo y | plink -pw {passw} {name}@{ip} pkill -f BruteForceSHA1CPU".format(
            passw=val["pass"],
            name=val["name"],
            ip=val["ip"]
            ), shell=True)
        subprocess.call("pscp -pw {passw} ./BruteForceSHA1CPU {name}@{ip}:\"{path}BruteForceSHA1CPU\"".format(passw=val["pass"],
                    name=val["name"],
                    ip=val["ip"],
                    path=val["path"]), shell=True)
        subprocess.call("plink -pw {passw} {name}@{ip} \"chmod +x {path}BruteForceSHA1CPU; ldd {path}BruteForceSHA1CPU\"".format(passw=val["pass"],
                    name=val["name"],
                    ip=val["ip"],
                    path=val["path"]), shell=True)

def RunCPUFarm(authdata):
    for val in settings_linux_CPU_farm:
        threading.Thread(target=Worker, args=("plink -pw {passw} {name}@{ip} {path}BruteForceSHA1CPU {authdata}".format(
            passw=val["pass"],
            name=val["name"],
            ip=val["ip"],
            path=val["path"],
            authdata=authdata.decode("UTF-8")
            ),)).start()

def Worker(str_in):
    try:
        result = subprocess.check_output(str_in, shell=True)
    except :
        logging.debug("BruteForceSHA1CUDA is quited")
        return
    global result_suffix
    result_suffix = bytes([int(c, 16) for c in result.strip().split(b" ")])
    logging.debug(b"good - " + result_suffix)
    event_suffix_found.set()

def MainFunc():    
    host_addr = 'xxx'
    host_port = 0000
    server_sni_hostname = 'zzz'
    server_cert = 'server.crt'
    client_cert = 'client.crt'
    client_key = 'client.key'
    
    ssl._create_default_https_context = ssl._create_unverified_context
    context = ssl._create_unverified_context()
    context.load_cert_chain(certfile=client_cert, keyfile=client_key)
    
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    conn = context.wrap_socket(s, server_side=False, server_hostname=server_sni_hostname)
    conn.connect((host_addr, host_port))
    authdata = ""
    difficulty = 0
    #StopAllCPUFarm()
    subprocess.call("taskkill /IM BruteForceSHA1CUDA.exe /T /F")
    time.sleep(5)
    while True:
        read_val = conn.read()
        args = read_val.strip().split(b' ')
    
        if args[0] == b"HELO":
    
            conn.write(b"ZEISOOX\n")
            logging.debug("hello recieved")
    
        elif args[0] == b"ERROR":
    
            logging.debug(b"ERROR: " + b" ".join(args[1:]))
    
            break
    
        elif args[0] == b"POW":
    
            authdata, difficulty = args[1], int(args[2])
            logging.debug(authdata)
            logging.debug(difficulty)
    
            # Starting local CUDA farm
            threading.Thread(target=Worker, args=(".\\BruteForceSHA1CUDA.exe {}".format(authdata.decode("UTF-8")),)).start()
            #RunCPUFarm(authdata)
            if not event_suffix_found.wait(7140):
                subprocess.call("taskkill /IM BruteForceSHA1CUDA.exe /T /F")
                logging.debug("Before sending wrong value")
                conn.write(b"123\n")
                logging.debug("After sending wrong value")
                #StopAllCPUFarm()
                #logging.debug("Nothing happends")
                #exit(0)
            else:
                event_suffix_found.clear()
                conn.write(result_suffix + b"\n")
                logging.debug(result_suffix + b"\n")
    
        elif args[0] == b"END":
    
            # if you get this command, then your data was submitted
    
            conn.write(b"OK\n")
            logging.debug(args[0])
            logging.debug(b"OK\n")
            conn.close()

            exit(0)
    
        # the rest of the data server requests are required to identify you
    
        # and get basic contact information
    
        elif args[0] == b"NAME":
    
            # as the response to the NAME request you should send your full name
    
            # including first and last name separated by single space
    
            conn.write(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"Your Name\n")
            logging.debug(args[0])
            logging.debug(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"Your Name\n")
    
        elif args[0] == b"MAILNUM":
    
            # here you specify, how many email addresses you want to send
    
            # each email is asked separately up to the number specified in MAILNUM
    
            conn.write(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"1\n")
            logging.debug(args[0])
            logging.debug(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"1\n")
    
        elif args[0] == b"MAIL1":
    
            conn.write(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"your e-mail\n")
            logging.debug(args[0])
            logging.debug(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"your e-mail\n")
    
        elif args[0] == b"SKYPE":
    
            # here please specify your Skype account for the interview, or N/A
    
            # in case you have no Skype account
    
            conn.write(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"your skype\n")
            logging.debug(args[0])
            logging.debug(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"your skype\n")
    
        elif args[0] == b"BIRTHDATE":
    
            # here please specify your birthdate in the format %d.%m.%Y
    
            conn.write(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"birthday\n")
            logging.debug(args[0])
            logging.debug(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"birthday\n")
    
        elif args[0] == b"COUNTRY":
    
            # country where you currently live and where the specified address is
    
            # please use only the names from this web site:
    
            #   https://www.countries-ofthe-world.com/all-countries.html
    
            conn.write(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"Country\n")
            logging.debug(args[0])
            logging.debug(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"Country\n")
    
        elif args[0] == b"ADDRNUM":
    
            # specifies how many lines your address has, this address should
    
            # be in the specified country
    
            conn.write(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"2\n")
            logging.debug(args[0])
            logging.debug(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"2\n")
    
        elif args[0] == b"ADDRLINE1":
    
            conn.write(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"Street and so on\n")
            logging.debug(args[0])
            logging.debug(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"Street and so on\n")
    
        elif args[0] == b"ADDRLINE2":
    
            conn.write(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"City and so on\n")
            logging.debug(args[0])
            logging.debug(hashlib.sha1(authdata + args[1]).hexdigest().encode('utf8') + b" " + b"City and so on\n")
    
    conn.close()
    return False

if __name__ == '__main__':
    #UpdateAllCPUFarmWithNewVersion()
    #exit(0)
    #StopAllCPUFarm()
    #exit(0)
    while True:
        try: 
            MainFunc()
        except Exception as ex:
            logging.debug("Something error - " + str(ex))
            time.sleep(5)