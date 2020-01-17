#/bin/bash

# checks for correct installation
if [ ! $(docker -v | grep -c -w version) -eq 1 ]; then
	echo "docker not found."
	exit 1
fi
if [ ! $(groups | grep -c -w docker) -eq 1 ]; then
	echo "add current user $(whoami) to docker group!"
	exit 1
fi

# build containter
echo "start building Docker container 'mied-documentation'"
docker build -t mies-documentation .
# run doxygen and print version string
echo "Doxygen version" $(docker run --rm mies-documentation doxygen -v)
# execute build script
docker run --rm -v $(git rev-parse --show-toplevel):/opt/mies mies-documentation /bin/bash /opt/mies/tools/build-documentation.sh
