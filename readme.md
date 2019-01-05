# Docker-based pipeline test

## Dependencies
Docker
Nextflow

## Set up docker image

### Build
docker build -t davideyre:pipeline-test .

### Run in background and keep running; also mount local folder within image
docker run -d -t --name pipeline-test -v /Users/davideyre/Drive/academic/infrastructure/nextflow/pipeline-test/example_data:/data davideyre:pipeline-test

-d allows to run in background
-t keeps running

### Access the container
docker exec -it pipeline-test bash



### remove the whole set up
docker stop pipeline-test
docker container ls -a
docker container rm ba7b643f1e55 (alternative to remove all stopped containers - docker container prune)
docker image ls -a
docker image rm davideyre:pipeline-test



##Run Nextflow

### set up nextflow config
 - add the parameters for using docker and where to mount the local folder

### run the command
nextflow run check_qc_test.nf -with-report

### clean up
once has run, provided the files of interest are published with the copy option set, can then delete the work directory, this could be done on an automated basis, e.g. for files >1 week old in a production environment

## Resources

### Example docker files
https://hub.docker.com/r/biocontainers/bwa/dockerfile
https://hub.docker.com/r/biocontainers/biocontainers/dockerfile