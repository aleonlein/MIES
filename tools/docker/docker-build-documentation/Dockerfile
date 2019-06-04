FROM debian:experimental
MAINTAINER Matthias J. Kastner matthias.kastner@byte-physics.de

# MIES documentation script
#
# tools/build-documentation.sh

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && \
	apt-get install -y \
		doxygen \
		gawk \
		git \
		graphviz \
		pandoc \
		python3 \
		python3-pip \
		zip && \
	apt-get clean

RUN DEBIAN_FRONTEND=noninteractive \
	pip3 install \
		breathe \
		'sphinx<2,>=1.1.3' \
		sphinxcontrib-fulltoc \
		sphinxcontrib-images

# [optional] IPNWB submodule script
#
# Packages/IPNWB/update_doc.sh

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && \
	apt-get install -y \
		git \
		jq && \
	apt-get clean

RUN DEBIAN_FRONTEND=noninteractive \
	pip3 install \
		'json2yaml==1.1.1' \
		'yq==2.10.0'

WORKDIR /opt/mies/tools/
