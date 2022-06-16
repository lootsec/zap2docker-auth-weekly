# Customized Owasp ZAP Dockerfile with support for authentication

FROM owasp/zap2docker-stable
LABEL maintainer="Lootsec"

USER root


RUN mkdir /zap/wrk \ 
	&& cd /opt \
	&& wget -qO- -O geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v0.30.0/geckodriver-v0.30.0-linux64.tar.gz \
	&& tar -xvzf geckodriver.tar.gz \
	&& chmod +x geckodriver \
	&& ln -s /opt/geckodriver /usr/bin/geckodriver \
	&& export PATH=$PATH:/usr/bin/geckodriver

# Set up the Chrome PPA
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

# Update the package list and install chrome
RUN apt-get autoclean -y
RUN apt-get update -y

# Set up Chromedriver Environment variables
ENV CHROMEDRIVER_VERSION 100.0.4896.20
ENV CHROMEDRIVER_DIR /chromedriver
RUN mkdir $CHROMEDRIVER_DIR
ARG CHROME_VERSION="100.0.4896.60-1"

# Download and install Chromedriver
RUN wget -q --continue -P $CHROMEDRIVER_DIR "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
RUN unzip $CHROMEDRIVER_DIR/chromedriver* -d $CHROMEDRIVER_DIR
RUN wget --no-verbose -O /tmp/chrome.deb https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}_amd64.deb \
  && apt install -y /tmp/chrome.deb --allow-downgrades 2> /dev/null \
  && rm /tmp/chrome.deb

# Put Chromedriver into the PATH
ENV PATH $CHROMEDRIVER_DIR:$PATH

RUN git clone https://github.com/lootsec/zap2docker-auth-weekly.git 
RUN cp -rlf zap2docker-auth-weekly/* /zap/
RUN cp -rlf zap2docker-auth-weekly/.* /zap/
RUN rm -r zap2docker-auth-weekly/

ADD scripts /home/zap/.ZAP_D/scripts/scripts/active/
RUN chmod 777 /home/zap/.ZAP_D/scripts/scripts/active/ \
	&& chown -R zap:zap /zap/

USER zap

RUN pip install -r /zap/requirements.txt --no-warn-conflicts

VOLUME /zap/wrk
WORKDIR /zap
