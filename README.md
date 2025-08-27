# Hashtopolis-JohnTheRipper-shim
This project provides a shim to enable John the Ripper (JtR) support in Hashtopolis, allowing JtR to be used as a cracker within the Hashtopolis environment.

This hacky PoC demonstrates the functionality of integrating JtR with Hashtopolis (https://github.com/openwall/john/issues/4576).

# Overview
The `hashcat.bin` file creates a symbolic link to `process.sh`, which invokes hashcat using the `--stdout` option to generate candidate hashes (with configurable `--skip` and `--limit` values) that are then piped into JtR for cracking.

Default example is md5, edit `process.sh` and change `--format=raw-md5` for other attack modes.

## Support
This PoC is using the following versions of Hashcat and JtR:
* [Hashcat 7.1.2](https://github.com/hashcat/hashcat/releases/download/v7.1.2/hashcat-7.1.2.7z)
* JohnTheRipper [53674043c9cf4ece82a649e4f5834fd52f602935](https://github.com/openwall/john/tree/53674043c9cf4ece82a649e4f5834fd52f602935)

By deploying the 7z in the following Hashtopolis versions:
* Hashtopolis server [aadb30798299cc1b4b0ad2d7ef20c7ca307094c0](https://github.com/hashtopolis/server/tree/aadb30798299cc1b4b0ad2d7ef20c7ca307094c0)
* Hashtopolis python-agent [e2e7acb39755d12c5349a7c86cfa5c63af867ae6](https://github.com/hashtopolis/agent-python/tree/e2e7acb39755d12c5349a7c86cfa5c63af867ae6)


# Setting Up JtR-Shim Locally with Dev Containers & Docker
To test this locally, start with installing VSCode, together with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers). The remaining instructions for setup are based on the [Hashtopolis development environment wiki](https://github.com/hashtopolis/server/wiki/Development-environment) .

## 0. Get the JtR shim cracker
Get the Hashtopolis-JohnTheRipper-shim cracker to add later to Hashtopolis:
Artifacts are available from the [GitHub Actions runs](/actions/).
- Open the latest successful run and download the `Hashtopolis-JtR-shim-agent` artifact.
- Unzip the `Hashtopolis-JtR-shim-agent-$GIT-COMMIT-HASH.zip` with 
```commandline
unzip Hashtopolis-JtR-shim-agent-$GIT-COMMIT-HASH.zip
```
such that you end up with the resulting file: `Hashtopolis-JtR-shim-agent.7z`. This file will be added as a cracker to Hashtopolis later.

## 1. Clone Hashtopolis Server and start container
```
git clone https://github.com/hashtopolis/server
cd server
code .
```
Open the VSCode's dev container (`Ctrl + Shift + P` → "Open Folder in Container"). Wait for the logs to load.


## 2. Access the webinterface and add a voucher
Once the dev container is opened, re-run the project (`F5` in VSCode) try to access the Hashtopolis webinterface at:
```
http://127.0.0.1:8080/agents.php?new=true 
```
And log in with the following credentials: 
- user: `admin`
- password: `hashtopolis`

If the host is unreachable try looking at the docker logs using the `docker logs` command in a terminal and read the output to resolve any possible errors.

Next, in the **Add new agent** webinterface, add a new voucher. The vouchers will not expire in the Hashtopolis dev container.

## 3. Set Up Hashtopolis Python Agent
Clone the Hashtopolis Python agent repository and open it in VSCode:

```
git clone https://github.com/hashtopolis/agent-python
cd agent-python
code .
```

Reopen in the dev container (`Ctrl + Shift + P` → "Open Folder in Container") and run it once. This may take a while, look at the logs to see the progress.

Run the project once (`F5` in VSCode). It will not be able to find the server for the first run, but it will create a file called `config.json` which needs to be edited.

Edit `config.json` by updating the `"url"` field:

```
"url": "http://hashtopolis-server-dev/api/server.php"
```
Run the project again (`F5` in VSCode) and the Hashtopolis agent should be waiting for tasks to pick up. 

## 4. Copy JtR-Shim to hashtopolis-server
Now the John The Ripper shim can be added as cracker to Hashtopolis.
In the Hashtopolis server directory, create a `crackers` folder:
```
mkdir src/static/crackers
```
Copy the Hashtopolis-JtR Shim Agent (`Hashtopolis-JtR-shim-agent.7z`) to the `crackers` folder:
```
cp Hashtopolis-JtR-shim-agent.7z src/static/crackers
```
To verify if it is added correctly, check if the `7z` can be downloaded through the following url:
```
http://127.0.0.1:8080/static/crackers/Hashtopolis-JtR-shim-agent.7z
```
## 5. Add the Cracker to Hashtopolis
To add a new cracker, navigate to:
```
http://127.0.0.1:8080/crackers.php?id=1&new=true
```
And fill in the information as follows:
- **Binary Version:** `7.0.0`
- **Binary Base name:** `hashcat`
- **Download URL:** `http://hashtopolis-server-dev/static/crackers/Hashtopolis-JtR-shim-agent.7z`

## 6. Add a New MD5 Hashlist to Hashtopolis
To verify if the new cracker works, add a test-hash to Hashtopolis.
Create a new hashlist in the Hashtopolis webinterface by navigating to:
```
http://127.0.0.1:8080/hashlists.php?new=true
```
Add a new hashlist of hashtype `MD5` with the following hash:
```
8743b52063cd84097a65d1633f5c74f5
```

## 7. Crack the hash with John the Ripper
- Add a new task to Hashtopolis by navigating to:
```
http://127.0.0.1:8080/tasks.php?new=true
```
- Select the created `MD5` hashlist and enter the following in the `Command line` field:
```
#HL# -a3 h?l?l?l?l?l?l
```
- Set the `Priority` to any number higher than 0 
- Set the `Binary type to run task` to `hashcat` and `7.0.0`

The agent should now download and execute the new cracker. 
Look at the logs of the Hashtopolis Agent (which is likely already open in VSCode).  

## Future work
This PoC is only to demonstrate John The Ripper *can* be used in Hashtopolis. It is not production ready at all.
Here are a few things for improvement:
 - Refactor the [agent-python/htpclient/hashcat_cracker.py](https://github.com/hashtopolis/agent-python/blob/master/htpclient/hashcat_cracker.py) script to create a `john_cracker.py`. This will provide better flexibility and allow for the following:
    - Use the `--node` option in JtR
    - Parse and report JtR's status output (currently only the progress is reported as 100%)
- Implementing a flexible shim to translate hashcat attack modes to JtR’s `--format`.

# Creating the 7z archive
To package the JtR shim, ensure you retain the symbolic link and run:
```
7z a Hashtopolis-JtR-shim-agent.7z -snl *
```