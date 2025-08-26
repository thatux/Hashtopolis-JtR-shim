# Hashtopolis-JohnTheRipper-shim
This project provides a shim to enable John the Ripper (JtR) support in Hashtopolis, allowing JtR to be used as a cracker within the Hashtopolis environment.

This hacky PoC demonstrates the functionality of integrating JtR with Hashtopolis (https://github.com/openwall/john/issues/4576).

# Overview
The `hashcat.bin` file creates a symbolic link to `process.sh`, which invokes hashcat using the `--stdout` option to generate candidate hashes (with configurable `--skip` and `--limit` values) that are then piped into JtR for cracking.

Default example is md5, edit `process.sh` and change `--format=raw-md5` for other attack modes.

## Support
This PoC is using the following versions of Hashcat and JtR:
* Hashcat [bb27e85faec3343a26f2d475708f6f38d6245e38](https://github.com/hashcat/hashcat/tree/bb27e85faec3343a26f2d475708f6f38d6245e38)
* JohnTheRipper [53674043c9cf4ece82a649e4f5834fd52f602935](https://github.com/openwall/john/tree/53674043c9cf4ece82a649e4f5834fd52f602935)

By deploying the 7z in the following Hashtopolis versions:
* Hashtopolis server [aadb30798299cc1b4b0ad2d7ef20c7ca307094c0](https://github.com/hashtopolis/server/tree/aadb30798299cc1b4b0ad2d7ef20c7ca307094c0)
* Hashtopolis python-agent [e2e7acb39755d12c5349a7c86cfa5c63af867ae6](https://github.com/hashtopolis/agent-python/tree/e2e7acb39755d12c5349a7c86cfa5c63af867ae6)


# Setting Up JtR-Shim Locally with Dev Containers & Docker
To test this locally, start with installing VSCode, together with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers). The remaining instructions for setup are based on the [Hashtopolis development environment wiki](https://github.com/hashtopolis/server/wiki/Development-environment) .

## 0. Pull this repository
Make sure to pull large files from this repository:
```
git lfs pull
```

## 1. Clone Hashtopolis Server
```
git clone https://github.com/hashtopolis/server
cd server
code .
```

## 2. Update `docker-entrypoint.sh` to Disable SSL
In the `docker-entrypoint.sh` file, add `--skip-ssl` to the MYSQL command:
```
MYSQL="mysql -u${HASHTOPOLIS_DB_USER} -p${HASHTOPOLIS_DB_PASS} -h ${HASHTOPOLIS_DB_HOST} --skip-ssl"
```
Reopen in VSCode's dev container (`Ctrl + Shift + P` → "Open Folder in Container"). Wait for the logs to load.

## 3. Access the webinterface and add `devvoucher`
Once the dev container is opened, re-run the project (`F5` in VSCode) try to access the Hashtopolis UI at:
```
http://127.0.0.1:8080/agents.php?new=true 
```
If this host is unreachable, run `docker-entrypoint.sh` in the terminal and read the output. It may direct you to a different endpoint or show an error to resolve first. 

When the endpoint is accessible log in using:
- user: `admin`
- password: `hashtopolis`

Next, in the **Add new agent** webinterface, add a new voucher with the string `devvoucher`.

## 4. Set Up Hashtopolis Python Agent
Clone the Hashtopolis Python agent repository and open it in VSCode:

```
git clone https://github.com/hashtopolis/agent-python
cd agent-python
code .
```

Next, replace all the `\t` characters in the code-base (use `Ctrl + Shift + H` to search and replace in all files with VSCode ) :
- Search for `-p "\t"` and replace it with `-p "0x09"`
- Search for `args.append('"\t"')` and replace it with `args.append('"0x09"')`

Reopen in the dev container (`Ctrl + Shift + P` → "Open Folder in Container") and run it once. This may take a while, look at the logs to see the progress.

Run the project once (`F5` in VSCode) and read the logs. It will probably not be able to find the server but it should have created the file `config.json`. 

Edit `config.json` and update the `"url"` field to:

```
"url": "http://hashtopolis-server-dev/api/server.php"
```

Run it again and now the agent should succesfully connect.

## 5. Copy JtR-Shim to hashtopolis-server
In the Hashtopolis server directory, create a `crackers` folder:
```
mkdir src/static/crackers
```
Copy the Hashtopolis-JtR Shim Agent archive to the `crackers` folder:
```
cp Hashtopolis-JtR-shim-agent.7z src/static/crackers
```
You can now download it from the following URL:
```
http://127.0.0.1:8080/static/crackers/Hashtopolis-JtR-shim-agent.7z
```
## 6. Add the Cracker to Hashtopolis
To add a new cracker, navigate to:
```
http://127.0.0.1:8080/crackers.php?id=1&new=true
```
Select version 7.0.0, and choose **hashcat**. Enter the following path for the cracker file:
```
http://hashtopolis-server-dev/static/crackers/Hashtopolis-JtR-shim-agent.7z
```

## 7. Add a New MD5 Hashlist to Hashtopolis
Create a new hashlist in the Hashtopolis webinterface by navigating to:
```
http://127.0.0.1:8080/hashlists.php?new=true
```
Add a new hashlist of hashtype `MD5` with the following hash:
```
8743b52063cd84097a65d1633f5c74f5
```
Add a new task to Hashtopolis by navigating to:
```
http://127.0.0.1:8080/tasks.php?new=true
```
Select the created `MD5` hashlist and enter the following in the `Command line` field:
```
#HL# -a3 h?l?l?l?l?l?l
```
Set the `Priority` to any number higher than 0 .


The agent should now download and execute the new cracker. Look at the logs in the VSCode window which has the Hashtopolis Agent codebase open.  

If you get **'Speed benchmark failed!'** double-check the replacements (`ctrl-shift-h`) made to the Python agent. Are all:  
- `-p "\t"` replaced to `-p "0x09"`
- `-p \"\t\"` replaced to `-p \"0x09\"` 
-  `args.append('"\t"')` replaced to `args.append('"0x09"')` 


## Future work
 - Refactor the [agent-python/htpclient/hashcat_cracker.py](https://github.com/hashtopolis/agent-python/blob/master/htpclient/hashcat_cracker.py) script to create a `john_cracker.py`. This will provide better flexibility and allow for the following:
    - Use the `--node` option in JtR
    - Parse and report JtR's status output (currently only the progress is reported as 100%)
- Implementing a flexible shim to translate hashcat attack modes to JtR’s `--format`.

# Creating the 7z archive
To package the JtR shim, ensure you retain the symbolic link and run:
```
7z a Hashtopolis-JtR-shim-agent.7z -snl *
```