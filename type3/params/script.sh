#!/bin/bash
ausearch -c 'nginx' --raw | audit2allow -M nginx-custom-port
semodule -i nginx-custom-port.pp
