#!/bin/sh
[ -e /usr/bin/pip    ] || ln -s /usr/local/bin/pip3.13 /usr/bin/pip
[ -e /usr/bin/pip3   ] || ln -s /usr/local/bin/pip3.13 /usr/bin/pip3
[ -e /usr/bin/python ] || ln -s /usr/local/bin/python3 /usr/bin/python
[ -e /usr/lib/libpython3.13.so.1.0 ] || ln -s /usr/local/lib/libpython3.13.so.1.0 /usr/lib/libpython3.13.so.1.0
scriptdir=$(dirname $0)
pip install -U pip
pip install -r ${scriptdir}/requirements.txt
