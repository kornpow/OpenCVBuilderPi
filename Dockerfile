# base-image for python on any machine using a template variable,
# see more about dockerfile templates here:http://docs.resin.io/pages/deployment/docker-templates
#1
FROM kornpow/opencvbuilder:1.0.0

WORKDIR /usr/src/app
COPY start /usr/src/app/start
CMD ["bash", "start"]

