#!/usr/bin/env python
# -*- coding: utf-8 -*-

import socket

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("localhost", 8888))

    # Placeholder shellcode, will be updated by the script
    shellcode = "\xb8\x01\x00\x00\x00\x85\xc9\x74\x05\xf7\xe3\x49\xde\x75\xfb\xc3"

    print("Sending shellcode (" + str(len(shellcode)) + " bytes)")
    s.send(shellcode)

if __name__ == "__main__":
    main()
