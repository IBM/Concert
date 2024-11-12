# Copyright IBM Corp. 2021, 2023.

# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

# hadolint ignore=DL3007
#FROM registry.access.redhat.com/ubi8/nodejs-20-minimal:latest
From node:18.18.1-alpine
USER root

ENV PYTHONUNBUFFERED=1
RUN apk add --no-cache python3 py3-pip make build-base
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools

#RUN npm -v
ENV PORT 8080
COPY . $HOME
#RUN npm install --omit=dev

#RUN yarn upgrade & yarn install
RUN yarn install --no-lockfile

USER 1001
EXPOSE 8080
#CMD [ "npm", "run", "-d", "start" ]
#CMD ["node", "server.js"]
CMD ["node", "./bin/www"]
