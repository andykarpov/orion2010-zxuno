#!/bin/env python

import sys

def main():
    if(len(sys.argv) != 2):
        print("Usage: %s <binfile>" % (sys.argv[0]))
        return
    infile = open(sys.argv[1], "rb", 0)
    outfile = open(sys.argv[1].replace(".bin", ".coe"), "w", 1)

    outfile.write("memory_initialization_radix=16;\nmemory_initialization_vector=\n");

    infile.seek(0, 2)
    inlen = infile.tell()
    infile.seek(0, 0)

    for i in range(inlen):
        outfile.write("%2x" % (infile.read(1)[0]))
        if(i == (inlen - 1)):
            outfile.write(";\n")
        else:
            outfile.write(",\n")
    
    infile.close()
    outfile.close()

main()

