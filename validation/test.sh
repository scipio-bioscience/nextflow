#!/bin/bash 
set -e 

get_abs_filename() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

export NXF_IGNORE_WARN_DSL2=true
export NXF_CMD=${NXF_CMD:-$(get_abs_filename ../launch.sh)}

#
# Tests
#
(
  cd ../tests/
  sudo bash cleanup.sh
  cd checks
  bash run.sh
)

if [[ $TEST_SMOKE == true ]]; then
  echo Skipping tests since TEST_SMOKE flag is true
  exit 0
fi

# disable ansi log to make log more readable
export NXF_ANSI_LOG=false

#
# Hello 
#
git clone https://github.com/nextflow-io/hello
( 
  cd hello; 
  $NXF_CMD run .
  $NXF_CMD run . -resume
)

#
# AMPA-NF
#
git clone https://github.com/cbcrg/ampa-nf
docker pull cbcrg/ampa-nf
(
  cd ampa-nf; 
  $NXF_CMD run . -with-docker 
  $NXF_CMD run . -with-docker -resume 
)

#
# RNASEQ-NF
#
echo nextflow-io/rnaseq-nf
[[ $TOWER_ACCESS_TOKEN ]] && OPTS='-with-tower' || OPTS=''
$NXF_CMD run nextflow-io/rnaseq-nf -with-docker $OPTS
$NXF_CMD run nextflow-io/rnaseq-nf -with-docker $OPTS -resume

if [[ $GITHUB_EVENT_NAME == pull_request ]]; then
  echo "Skipping cloud integration tests on PR event"
  exit 0
fi

#
# AWS Batch tests
#
if [ "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS batch tests"
  bash awsbatch.sh
else
  echo "Missing AWS_ACCESS_KEY_ID variable -- Skipping AWS Batch tests"
fi


#
# Azure Batch tests
#
if [ "$AZURE_BATCH_ACCOUNT_KEY" ] && [[ ${TEST_JDK} == 11 ]]; then
  echo "Azure batch tests"
  bash azure.sh
else
  echo "Missing AZURE_BATCH_ACCOUNT_KEY variable -- Skipping Azure Batch tests"
fi

#
# Google Life Sciences
#
if [ "$GOOGLE_SECRET" ]; then
  echo "Google LS tests"
  bash gls.sh
else
  echo "Missing GOOGLE_SECRET variable -- Skipping Google LS tests"
fi

