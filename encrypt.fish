#!/usr/bin/fish

openssl enc -aes-256-cbc -in $argv[1] -out "$argv[1].enc" -pbkdf2 -iter 100000 -pass "file:$HOME/Dokumente/.universal_enc_key.txt"
