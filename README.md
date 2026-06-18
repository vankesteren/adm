<div align="center">
  <img src="logo.svg" alt="adm">
  <h3>Admin commands for the department compute server</h3>
  <a href="https://github.com/vankesteren/adm/actions/workflows/ci.yml"><img src="https://github.com/vankesteren/adm/actions/workflows/ci.yml/badge.svg"></a>
</div>


## Installation 

`adm` is designed to run on an ubuntu server. It will probably also work on many other debian-derived systems. You can install it like so:

```sh
curl -fsSL https://raw.githubusercontent.com/vankesteren/adm/HEAD/install.sh | sh
```

If you're not a fan of [piping curl to bash](https://sasha.vincic.org/blog/2024/09/piping-curl-to-bash-convenient-but-risky), then download the install script from [here](./install.sh), review it, and run it.


## Usage

`adm` is documented quite well as a standard commandline tool -- running `adm --help` prints the following output:

```
 adm - lightweight sysadmin tool for compute server

 Usage:
   adm group command [options]

 Options:
   -h, --help       Show this help message and exit

 Available commands:
  adm disk usage - Show the disk usage per user
  adm self uninstall - Uninstall adm from this system
  adm self update - Update adm to the latest version
  adm user add - Add a user to the system
  adm user backup - Backup a user's home directory
  adm user delete - Delete a user from the system
  adm user email - Show or add email of a user
  adm user lastactivity - Show the last activity date of each user
  adm user list - List users and their emails
  adm user sudo - Add or remove a user from the sudo group
```
