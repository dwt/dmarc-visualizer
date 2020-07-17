#!/usr/bin/env python

import sys
import re
import os

possible_keys = os.environ.keys()

def substituter(match):
    string_to_replace =  match.group()
    environment_variable_name = string_to_replace[1:]
    if environment_variable_name in os.environ:
        return os.environ[environment_variable_name]
    else:
        return string_to_replace

with open(sys.argv[1]) as template:
    print(re.sub(r'\$\w+', substituter, template.read()))
