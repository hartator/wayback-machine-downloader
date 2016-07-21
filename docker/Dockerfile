FROM ruby:2.1
COPY ../ /build
RUN cd build && \
    bundle install && \
    cd .. && \
    rm -rf build
ENTRYPOINT [ "/usr/local/bundle/bin/wayback_machine_downloader" ]
