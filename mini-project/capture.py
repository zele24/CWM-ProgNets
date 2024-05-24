#!/usr/bin/env python3

import re
import binascii

from scapy.all import *

class Player(Packet):
    name = "Player"
    #setting default values
    fields_desc = [ ByteField("PlayerIn", 1),
                    ByteField("Team", 0),
                    ByteField("HasFlag", 0),
                    StrFixedLenField("op", "M", length=1),
                    
                    ShortField("X_Location", 0),
                    ShortField("Y_Location", 0),
                    
                    IntField("Assignment", 0),
                    IntField("result", 0xDEADBABE)]
'''
ShortField() = 16bits
ByteField() = 8bits
'''



bind_layers(Ether, Player, type=0x1234)

class NumParseError(Exception):
    pass

class OpParseError(Exception):
    pass

class Token:
    def __init__(self,type,value = None):
        self.type = type
        self.value = value

##Checks if the all of the input is a digit from 1-9
def num_parser(s, i, ts):
    pattern = "^\s*([0-9]+)\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError('Expected number literal.')

# Checks if the input is one of the allowable operations
def op_parser(s, i, ts):
    pattern = "^\s*([AMCFWSI])\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError("Expected capitalised operator 'M', 'C', 'F', 'W', 'A', 'S' or 'I'.")


def make_seq(p1, p2):
    def parse(s, i, ts):
        i,ts2 = p1(s,i,ts)
        return p2(s,i,ts2)
    return parse

def get_if():
    ifs=get_if_list()
    iface= "veth0-1" # "h1-eth0"
    #for i in get_if_list():
    #    if "eth0" in i:
    #        iface=i
    #        break;
    #if not iface:
    #    print("Cannot find eth0 interface")
    #    exit(1)
    #print(iface)
    return iface

def main():

##Check what p does and whether order for it matters
    p = make_seq(op_parser, make_seq(num_parser,make_seq(num_parser,num_parser)))
    s = ''
    ##iface = get_if()
    iface = "enx0c37965f8a26"
    

    while True:
        s = input('> ')
        if s == "quit":
            break
            
            ##Making sure all input fields are filled enev when it doesn't matter
        if len(s) == 1:
            s = s + ' 0' + ' 0' + ' 0'
            	
        if len(s) == 3:
            s = s + ' 0' + ' 0'
        #print(s)
        try:
            i,ts = p(s,0,[])
                       
            
            ##Setting the team of the controller based on which player is input
            
            if int(ts[1].value) == 0:
            	team = 0
            elif int(ts[1].value) == 1:
            	team = 0
            elif int(ts[1].value) == 2:
            	team = 1
            elif int(ts[1].value) == 3:
            	team = 1
            else:
            	team = 2
            
            
            
            pkt = Ether(dst='00:04:00:00:00:00', type=0x1234) / Player(op=(ts[0].value),
                                              Assignment=int(ts[1].value),
                                              X_Location=int(ts[2].value),
                                              Y_Location=int(ts[3].value),
                                              Team=int(team))

            
                                              
            pkt = pkt/' '

            #pkt.show()
            #xxx = pkt[Player]
            #print(xxx.op)
            
            
            resp = srp1(pkt, iface=iface,timeout=5, verbose=False)
            
            if resp:
                player=resp[Player]
                
                #player.show()
                
                if player:
                    raw = player.result
                    #print('raw:', raw)
                    
                    messageHex = str(hex(int(raw)))
                    messageHex = messageHex.split('x')
                    messageHex = messageHex[1]
                    messageBin = binascii.a2b_hex(messageHex)
                    message = messageBin.decode("utf-8")
                    
                    print(message)
                    
                    
                    if str(ts[0].value) == 'A':
                        player.show()
                    
                else:
                    print("Cannot find Player header in the packet")
            else:
                print("Didn't receive response")
        except Exception as error:
            print(error)


if __name__ == '__main__':
    main()



