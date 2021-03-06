#!/bin/bash

source "$(dirname $0)/common.sh"

ensure_bin 'mvn'
ensure_bin 'git'

mkdir_p $OUTPUT_DIR
mkdir_p $SITE_DIR
mkdir_p $ARCHIVE_DIR


if [ ! -d $JENKINS_DIR ]; then
    echo ">> ${JENKINS_DIR} does not exist, cloning repository"
    git clone https://github.com/jenkinsci/jenkins.git ${JENKINS_DIR}
else
    echo ">> ${JENKINS_DIR} already exists, updating refs"
    (cd $JENKINS_DIR && git fetch --all)
fi;


function generate_javadoc() {
    pushd $JENKINS_DIR
    git clean -xf
    git checkout $1
    nice mvn javadoc:aggregate

    if [ $? -ne 0 ]; then
        echo ">> failed to generate javadocs for ${1}"
    fi;

    mv target/site/apidocs ${ARCHIVE_DIR}/${1}
    popd
}

for release in 1.554 1.565 1.580 1.596 1.609 1.625 1.642 1.651 2.7; do
    echo ">> Found release ${release}"
    generate_javadoc "jenkins-${release}"
done;

pushd $JENKINS_DIR
    generate_javadoc $(git tag -l jenkins-\* | sort --version-sort --reverse | head -n 1)
popd;
