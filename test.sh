#!/usr/bin/env bash
# tests for adm

check_cmd() {
  "$@"
  if [ $? -ne 0 ]; then
    echo "Error: command failed — $*" >&2
    exit 1
  fi
}

assert_eq() {
  if [ "$1" != "$2" ]; then
    echo "Assertion failed: expected '$1' == '$2'" >&2
    exit 1
  fi
}

# make /data dir
mkdir /data

# first, add some users
check_cmd echo "y" | adm user add testuser1 testpass1 test1@test.com
check_cmd echo "y" | adm user add testuser2 testpass2 test2@test.com
check_cmd echo "y" | adm user add testuser3 testpass3 test3@test.com

# add a file
echo "this is some text for testing" > /data/testuser1/myfile.txt

# test adm, quite rudimentary but does the basic job
check_cmd adm --help
check_cmd adm disk usage --sort
check_cmd adm user backup testuser1
check_cmd adm user list
check_cmd adm user email testuser2
check_cmd adm user email testuser2 test23@test.com
assert_eq $(adm user email testuser2) "<test23@test.com>"
check_cmd adm user lastactivity
check_cmd echo "testuser2" | adm user delete testuser2
check_cmd adm self update
