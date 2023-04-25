import serial
import pexpect
from signal import signal, SIGPIPE, SIG_DFL

def is_attack_possible (tech, attack, ptr, loc, func):
  if attack == 200:
    if func != 500 and func != 508:
      return 0
  if attack == 203:
    if ptr not in [315, 316, 317]:
      return 0
    if (ptr == 316 or ptr == 317) and tech == 101:
      return 0
    if tech == 101 and loc == 401:
      return 0
  elif ptr in [315, 316, 317]:
    return 0
  if attack == 202 and tech != 100:
    return 0	
  if tech == 101 and ptr == 308 and loc == 402:
    if func != 500 and func != 502 and func != 508:
      return 0
  if tech == 100:
    if (loc == 400 and ptr == 300):
      return 1
    elif attack != 203:
      if(loc == 400 and ptr not in [301, 302, 306, 307, 311]):
        return 0
      elif(loc == 401 and ptr not in [303, 308, 312]):
        return 0
      elif(loc == 402 and ptr not in [304, 309, 314]):
        return 0
      elif(loc == 403 and ptr not in [305, 310, 313]):
        return 0
    elif ptr == 302:
      if func == 505 or func == 504 or func == 507 or func == 508:
        return 0
    elif ptr == 312 and attack != 200 and loc == 401:
      if func == 502:
        return 0
  return 1

def replace_all(text, dic):
  text2 = text
  for i, j in dic.items():
    text2 = text2.replace(i, j)
  return text2

signal(SIGPIPE,SIG_DFL) 

ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=2)

cmd = 'cd ~/risc-v/clean/cva6-softcore-contest && source /opt/Xilinx/Vivado/2020.1/settings64.sh  &&  make program_cva6_fpga && cd zephyr-docker/ && sudo docker run -ti --privileged -v /dev/bus/usb:/dev/bus/usb -v `realpath workspace`:/workdir zephyr-build:v1 /bin/bash -c "cd workdir/ ; export RIPEt={1} ; export RIPEi={2} ; export RIPEc={3} ; export RIPEl={4} ; export RIPEf={5} ; west build -p -b cv32a6_zybo /workdir/ripe_test/ ; west debug"'

n = 0
success = 0
stopped = 0
for_sure= 0
others  = 0

for i in range(100,102):
  for j in range(200,204):
    for k in range(300,318):
      for l in range(400,404):
        for m in range(500,509):
          if is_attack_possible(i,j,k,l,m):
            n+=1
            print("attack",n,"- success:", success, "| stopped:", stopped, "(for sure:", for_sure, ")| unavailable:", others)
            d = { "{1}": str(i), "{2}": str(j), "{3}": str(k), "{4}": str(l), "{5}": str(m)}
            cmd_i = replace_all(cmd, d)
            child = pexpect.spawn('bash')
            child.expect(r'\$')
            child.sendline("sudo kill -9 $(ps -aux | grep 'zephyr' | awk '{print $2}')")
            child.expect('password')
            child.sendline('Ubuntu@INSA31400')
            child.expect(r'\$')
            child.sendline(cmd_i)
            child.expect('Type <RET>', timeout=300)
            child.sendline('')
            child.expect('(gdb)', timeout=300)
            child.sendline('c')
            s = ser.read(1000).decode("utf-8") 
            lines = s.splitlines()
            if len(lines) > 2:
              print(lines[2])
            if len(lines) > 3:
              print(lines[3])
            if len(lines) > 4:
              print(lines[4])
            if len(lines) > 5:
              print(lines[5])
            if len(lines) > 6:
              print(lines[6])
            print(lines[len(lines)-1])
            if "success" in s:
              success+=1
            elif "Error:" in s:
              others+=1
            elif s.endswith("Executing attack... "):
              stopped+=1
              for_sure+=1
            else:
              stopped+=1
            
