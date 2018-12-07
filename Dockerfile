# base-image for python on any machine using a template variable,
# see more about dockerfile templates here:http://docs.resin.io/pages/deployment/docker-templates
#1
FROM resin/raspberry-pi-python:3.4-slim


SHELL ["/bin/bash", "-c"]

# use apt-get if you need to install dependencies,
# for instance if you need ALSA sound utils, just uncomment the lines below.
#2
RUN apt-get update && apt-get install --no-install-recommends -yq \
build-essential cmake pkg-config git \
libjpeg-dev libtiff5-dev libjasper-dev libpng12-dev \
libv4l-dev \
libatlas-base-dev gfortran \
python3-dev python2.7-dev \
python3-venv curl  \
wget unzip \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install python3-pip

RUN python3 -m venv /env

# Set our working directory
#3
WORKDIR /usr/src/app

COPY ./requirements.txt /requirements.txt



RUN bash -c "source /env/bin/activate && pip3 install -Ur /requirements.txt --only-binary=:all: --python-version 34 --implementation cp --abi cp34m --platform=linux_armv6l --extra-index-url https://www.piwheels.org/simple -v --target /env/lib/python3.4/site-packages"


#COPY ./opencv-3.4.4/ /usr/src/app/opencv-3.4.4/

RUN wget https://github.com/opencv/opencv/archive/3.4.4.zip && unzip 3.4.4.zip

WORKDIR /usr/src/app/opencv-3.4.4/

RUN mkdir build && \
	sed -i -e 's/#define DEFAULT_V4L_WIDTH  640/#define DEFAULT_V4L_WIDTH  1280/g' modules/videoio/src/cap_v4l.cpp && \
	sed -i -e 's/#define DEFAULT_V4L_HEIGHT 480/#define DEFAULT_V4L_HEIGHT 720/g' modules/videoio/src/cap_v4l.cpp && \
	sed -i -e 's/#define DEFAULT_V4L_WIDTH  640/#define DEFAULT_V4L_WIDTH  1280/g' modules/videoio/src/cap_libv4l.cpp && \
	sed -i -e 's/#define DEFAULT_V4L_HEIGHT 480/#define DEFAULT_V4L_HEIGHT 720/g' modules/videoio/src/cap_libv4l.cpp


RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D BUILD_SHARED_LIBS=OFF \
	-D PYTHON3_EXECUTABLE=$(which python3) \
	-D PYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
	-D PYTHON_INCLUDE_DIR2=$(python3 -c "from os.path import dirname; from distutils.sysconfig import get_config_h_filename; print(dirname(get_config_h_filename()))") \
	-D PYTHON_LIBRARY=$(python3 -c "from distutils.sysconfig import get_config_var;from os.path import dirname,join ; print(join(dirname(get_config_var('LIBPC')),get_config_var('LDLIBRARY')))") \
	-D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "import numpy; print(numpy.get_include())") \
	-D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
	-D WITH_V4L=ON -D WITH_LIBV4L=ON .. 


RUN make -j8

RUN make install
RUN ldconfig

#10
WORKDIR /usr/src/app/


# switch on systemd init system in container
#12
ENV INITSYSTEM on

RUN apt-get update && apt-get install nano

# main.py will run when container starts up on the device
#13

CMD ["bash", "start"]
