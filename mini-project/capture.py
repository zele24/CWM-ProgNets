#!/usr/bin/env python3

import re

from scapy.all import *

class Player(Packet):
    name = "Player"
    #setting default values
    fields_desc = [ IntField("PlayerIn", 1),
                    IntField("Team", 0),
                    IntField("HasFlag", 0)
                    StrFixedLenField("op", "M", length=1),
                    IntField("X-Location", 0),
                    IntField("Y-Location", 0),
                    IntField("result", 0xDEADBABE)]

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
    pattern = "^\s*([MCFWSI])\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError("Expected capitalised operator 'M', 'C', 'F', 'W', 'S' or 'I'.")


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

    p = make_seq(num_parser, make_seq(op_parser,num_parser))
    s = ''
    #iface = get_if()
    iface = "enx0c37965f8a26"

    while True:
        s = input('> ')
        if s == "quit":
            break
        print(s)
        try:
            i,ts = p(s,0,[])
            pkt = Ether(dst='00:04:00:00:00:00', type=0x1234) / Player(op=ts[1].value,
                                              operand_a=int(ts[0].value),
                                              operand_b=int(ts[2].value))

            pkt = pkt/' '

            #pkt.show()
            resp = srp1(pkt, iface=iface,timeout=5, verbose=False)
            if resp:
                Player=resp[Player]
                if Player:
                    print(Player.result)
                else:
                    print("cannot find Player header in the packet")
            else:
                print("Didn't receive response")
        except Exception as error:
            print(error)


if __name__ == '__main__':
    main()


