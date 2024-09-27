FROM rocker/geospatial:4.3.3

ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV USERID="1000"
ENV USER="rstudio"
ENV GROUPID="1000"
ENV GROUPNAME="rstudio"

COPY scripts/install_jupyter.sh /rocker_scripts/install_jupyter.sh
COPY scripts/default_user.sh /rocker_scripts/default_user.sh
COPY scripts/start.sh /rocker_scripts/start.sh

RUN "/rocker_scripts/install_jupyter.sh"
RUN apt-get update && apt-get install -y gosu

EXPOSE 8888

CMD ["/bin/bash", "-c", "/rocker_scripts/default_user.sh ${USER} ${USERID} ${GROUPID} ${GROUPNAME} \
    && gosu ${USER} /rocker_scripts/start.sh"]