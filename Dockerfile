# docker build -t deployments/obor .
# docker run --net=host -it --rm -v $PWD:/deployments  -v $HOME/.ssh/id_rsa:/root/.ssh/id_rsa:ro deployments/obor

# Example:
# fab -H username@hostname update:host_dir=../../configs/obor/hostname,switch=yes

FROM python:2.7
RUN apt-get update && apt-get install -y vim rsync
WORKDIR /tmp
ADD requirements.txt /tmp
ADD dev-requirements.txt /tmp
RUN pip install -r requirements.txt
RUN pip install -r dev-requirements.txt
WORKDIR /deployments
CMD bash

