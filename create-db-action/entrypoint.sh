#!/bin/bash
set -e

init_path=$PWD
mkdir upload_packages
find $local_path -type f -name "*.tar.zst" -exec cp {} ./upload_packages/ \;

if [ ! -z "$gpg_key" ]; then
    echo "$gpg_key" | gpg --import
fi

cd upload_packages || exit 1

echo "::group::Adding packages to the repo"

repo-add "./${repo_name:?}.db.tar.gz" ./*.tar.zst

echo "::endgroup::" 

rm "./${repo_name:?}.db.tar.gz"
rm "./${repo_name:?}.files.tar.gz"

echo "::group::Signing packages"

if [ ! -z "$gpg_key" ]; then
    packages=( "*.tar.zst" )
    for name in $packages
    do
        gpg --detach-sig --yes $name
    done
    repo-add --verify --sign "./${repo_name:?}.db.tar.gz" ./*.tar.zst
fi

echo "::endgroup::" 