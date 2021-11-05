#!/usr/bin/env python3

import sys
import json
import re
import io
from pykospacing import Spacing

if __name__ == "__main__":
#    logging.basicConfig(level=logging.DEBUG, format="%(levelname)8s %(asctime)s %(message)s ")
    lines = ["이번엔될거라믿어"]
    spacing = Spacing()

    while True:
        sys.stdin.reconfigure(encoding='utf-8')
        sys.stdin.readline()
        if not l: break
        if l.strip() == "":
            if len(lines) > 0:
                sent = "".join(lines)
                new_sent = spacing(sent)
                new_sent = re.sub('(.*)', '\\1.', new_sent)
                print (new_sent)
                sys.stdout.flush()
                lines = []
            else:
                lines.append(l)

    if len(lines) > 0:
        sent = "".join(lines)
        new_sent = spacing(sent)
        new_sent = re.sub('(.*)', '\\1.', new_sent)
        print (new_sent)
        lines = []
                
