FROM archlinux:latest

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN date
RUN pacman -Syu --noconfirm
RUN pacman -S base-devel git python --noconfirm
COPY entrypoint.sh /entrypoint.sh
COPY encode_name.py /encode_name.py
ENTRYPOINT ["/entrypoint.sh"] 
