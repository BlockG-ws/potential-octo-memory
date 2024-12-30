Use Github Actions to build Arch packages.
# How to use
Go to releases and download packages, or use the repo: https://repo.grassblock.eu.org/gb-cha0s

1.import keys
```shell
wget -O /tmp/gb-cha0s.asc 'https://rawcdn.githack.com/BlockG-ws/potential-octo-memory/master/repo-sign.asc' && sudo pacman-key --add /tmp/gb-cha0s.asc
sudo pacman-key --lsign-key hi@imgb.space
```
2. add repo

edit /etc/pacman.conf
```
[gb-cha0s]
Server =  https://repo.grassblock.eu.org/gb-cha0s
```
3. sync
```shell
sudo pacman -Syu
```

# Contribute Guide

based on [vifly's post](https://viflythink.com/Use_GitHubActions_to_build_AUR/) (Chinese).

For package additions/deletions, please open a issue with package name and reasons.