FROM alpine

RUN apk update
RUN apk add --no-cache mongodb

RUN mkdir -p /data/db
CMD [ "mongod", "--bind_ip", "0.0.0.0" ]