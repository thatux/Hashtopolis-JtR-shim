# Hashtopolis-JohnTheRipper-shim

A binary cracker for Hashtopolis to be able to use JtR.

A hacky PoC albeit working stab at getting JtR working in Hashtopolis (https://github.com/openwall/john/issues/4576).

## Working
`hashcat.bin` symlinks to `process.sh` where `hashcat` is invoked using --stdout to generate candidates (with --skip and --limit) and piping them into JtR.

Default example is md5, edit `process.sh` and change `--format=raw-md5` for other attack modes.

## Versions
* Hashcat [bb27e85faec3343a26f2d475708f6f38d6245e38](https://github.com/hashcat/hashcat/tree/bb27e85faec3343a26f2d475708f6f38d6245e38)
* JohnTheRipper [53674043c9cf4ece82a649e4f5834fd52f602935](https://github.com/openwall/john/tree/53674043c9cf4ece82a649e4f5834fd52f602935)

Tested to be working with
* Hashtopolis server [aadb30798299cc1b4b0ad2d7ef20c7ca307094c0](https://github.com/hashtopolis/server/tree/aadb30798299cc1b4b0ad2d7ef20c7ca307094c0)
* Hashtopolis python-agent [e2e7acb39755d12c5349a7c86cfa5c63af867ae6](https://github.com/hashtopolis/agent-python/tree/e2e7acb39755d12c5349a7c86cfa5c63af867ae6)



## Trying out on local machine using dev-containers and docker
Install vscode, install [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), instructions based on https://github.com/hashtopolis/server/wiki/Development-environment
```
git clone https://github.com/hashtopolis/server
cd server
code .
# in docker-entrypoint.sh add --skip-ssl
#MYSQL="mysql -u${HASHTOPOLIS_DB_USER} -p${HASHTOPOLIS_DB_PASS} -h ${HASHTOPOLIS_DB_HOST} --skip-ssl"
code .
# reopen in dev container (ctrl-shift-p 'open folder in container'); show logs; wait
# press f5
# open http://127.0.0.1:8080/agents.php?new=true
# run ./docker-entrypoint.sh in the terminal if it's not working..
# user: admin
# password: hashtopolis
# add devvoucher as voucher


git clone https://github.com/hashtopolis/agent-python
cd agent-python
code .
# replace all (ctrl-shift-h) -p "\t" with -p "0x09", -p \"\t\" with -p \"0x09\" and args.append('"\t"') with args.append('"0x09"')
# reopen in dev container (ctrl-shift-p 'open folder in container'); show logs; wait
# run once (f5), stop running when error (can't find server)
# config.json is created now, edit it and make this the URL:
#   "url": "http://hashtopolis-server-dev/api/server.php"
# run once more, should be able to connect now..


# server and machine should be running now..

# In hashtopolis-server
mkdir src/static/crackers
cp Hashtopolis-JtR-shim-agent.7z src/static/crackers
# http://127.0.0.1:8080/static/crackers/Hashtopolis-JtR-shim-agent.7z should now download


# Add new cracker to hashtopolis: http://127.0.0.1:8080/crackers.php?id=1&new=true
7.0.0
hashcat
http://hashtopolis-server-dev/static/crackers/Hashtopolis-JtR-shim-agent.7z

# Add new md5 hashlist to Hashtopolis
# 8743b52063cd84097a65d1633f5c74f5

# Add new task to Hashtopolis
# #HL# -a3 h?l?l?l?l?l?l
# Make sure to set priority to 10 (default is 0..)

# The agent should now download the new cracker
# If you get 'Speed benchmark failed!' double check if you replaced (ctrl-shift-h) -p "\t" with -p "0x09", -p \"\t\" with -p \"0x09\" and args.append('"\t"') with args.append('"0x09"') in agent-python
```

## Future work
It would probably be much better to adjust [agent-python/htpclient/hashcat_cracker.py](https://github.com/hashtopolis/agent-python/blob/master/htpclient/hashcat_cracker.py) into `john_cracker.py`; that would allow:
- [ ] to try and use JtRs `--node` option
- [ ] to parse JtR status output; currently we only report progress (always 100%)

Some other ideas:
- [ ] have a flexible shim which translates hashcat attackmodes to JtR --format


# creating the 7z
make sure to keep the symlink
`7z a Hashtopolis-JtR-shim-agent.7z -snl *`