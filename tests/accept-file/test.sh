#!/usr/bin/env bash

printf '%.0s-' {1..80}
echo

URL=$1

COUNT_TESTS=0
COUNT_TESTS_FAIL=0

assertTrue() {
    testName="$3"
    pad=$(printf '%0.1s' "."{1..80})
    padlength=78

    if [ "$1" != "$2" ]; then
        printf ' %s%*.*s%s' "$3" 0 $((padlength - ${#testName} - 4)) "$pad" "Fail"
        printf ' (expected %s, assertion %s)\n' "$1" "$2"
        let "COUNT_TESTS_FAIL++"
    else
        printf ' %s%*.*s%s\n' "$3" 0 $((padlength - ${#testName} - 2)) "$pad" "Ok"
        let "COUNT_TESTS++"
    fi
}

testAcceptFile() {
    rm -rf /actual/out/*
    mkdir -p /actual/storage/9915e49a-4de1-41aa-9d7d-c9a687ec048d
    touch /actual/storage/9915e49a-4de1-41aa-9d7d-c9a687ec048d/dump1.sql
    touch /actual/storage/9915e49a-4de1-41aa-9d7d-c9a687ec048d/dump2.sql

    rsync --inplace -av /actual/storage/9915e49a-4de1-41aa-9d7d-c9a687ec048d rsync://storage/data


}

#testAcceptFile

printf '%.0s-' {1..80}
echo
printf 'Total test: %s, fail: %s\n\n' "$COUNT_TESTS" "$COUNT_TESTS_FAIL"

if [ $COUNT_TESTS_FAIL -gt 0 ]; then
    exit 1
fi

exit 0
