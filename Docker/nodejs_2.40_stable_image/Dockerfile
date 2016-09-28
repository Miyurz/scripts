FROM ubuntu:14.04
MAINTAINER Vforesee Labs

RUN sudo apt-get update
RUN sudo apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
RUN sudo apt-get install -y nodejs

#Install Python
RUN apt-get install -y python build-essential

# Create app directory
#RUN mkdir -p /usr/src/app
#WORKDIR /usr/src/app

# Install app dependencies
#COPY package.json /usr/src/app/
#RUN npm install

# Bundle app source
#COPY . /usr/src/app

#EXPOSE 3000
#EXPOSE 50051
#CMD [ "npm", "start" ]
