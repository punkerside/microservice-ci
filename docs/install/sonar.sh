#!/bin/bash

wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip
unzip sonar-scanner-cli-3.3.0.1492-linux.zip
mv sonar-scanner-3.3.0.1492-linux/ sonar-scanner/
mkdir bin
mv sonar-scanner/ bin/
