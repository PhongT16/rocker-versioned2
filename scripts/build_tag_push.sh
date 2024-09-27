VERSION=5
docker build --platform linux/amd64 -t myrstudio -f dockerfiles/binder_4.3.3.Dockerfile . 
docker tag myrstudio phongtran27/rstudio:v1.$VERSION
docker push phongtran27/rstudio:v1.$VERSION