#!/bin/bash
echo -n $(grep '^Version: ' control | sed 's/Version: //')
