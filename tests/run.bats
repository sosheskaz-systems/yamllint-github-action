#!/usr/bin/env bats

# NOTE: environment variable GITHUB_EVENT_PATH
# is required in a pullrequest scenario. If the variable
# is not set the test is gonna hang.

# functions ###################################################################
debug() {
  status="$1"
  output="$2"
  if [[ ! "${status}" -eq "0" ]]; then
  echo "status: ${status}"
  echo "output: ${output}"
  fi
}

###############################################################################
## test cases #################################################################
###############################################################################

function setup() {
  unset INPUT_YAMLLINT_FILE_OR_DIR
  unset INPUT_YAMLLINT_STRICT
  unset INPUT_YAMLLINT_CONFIG_FILEPATH
  unset INPUT_YAMLLINT_CONFIG_DATAPATH
  unset INPUT_YAMLLINT_FORMAT
  unset INPUT_YAMLLINT_COMMENT
  export ROOT_DIR="${ROOT_DIR:-$(git rev-parse --show-toplevel)}"
  export GITHUB_OUTPUT_FILE="${GITHUB_OUTPUT_FILE:-$(mktemp -p "${BATS_TMPDIR}")}"
  cp /dev/null "${GITHUB_OUTPUT_FILE}"
  export GITHUB_OUTPUT="${GITHUB_OUTPUT_FILE}"
}

## INPUT_YAMLLINT_FILE_OR_DIR #################################################
###############################################################################

## File
@test "INPUT_YAMLLINT_FILE_OR_DIR: valid single without warnings or errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/single_files/file2.yml"

  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"
  echo $output | grep -q "lint: info: successful yamllint on ${INPUT_YAMLLINT_FILE_OR_DIR}."
  [[ "${status}" -eq 0 ]]
}

@test "INPUT_YAMLLINT_FILE_OR_DIR: valid single with one errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/single_files/file1.yml"

  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "lint: error: failed yamllint on"
  echo $output | grep -q "line too long (114 > 80 characters)"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

## folder
@test "INPUT_YAMLLINT_FILE_OR_DIR: nested_folder with one errors" {
  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/nested_folder" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "lint: error: failed yamllint on"
  echo $output | grep -q "line too long (115 > 80 characters)"
  [[ "${status}" -eq 1 ]]
}

## INPUT_YAMLLINT_COMMENT #################################################
###############################################################################

### enabled (1,true)
@test "INPUT_YAMLLINT_COMMENT: set 1 in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/single_files/file1.yml"

  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  INPUT_YAMLLINT_COMMENT="1" \
  GITHUB_EVENT_PATH="/tmp/" \
  GITHUB_EVENT_NAME="pull_request" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -q "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

@test "INPUT_YAMLLINT_COMMENT: set true in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/single_files/file1.yml"

  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  INPUT_YAMLLINT_COMMENT="true" \
  GITHUB_EVENT_PATH="/tmp/" \
  GITHUB_EVENT_NAME="pull_request" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -q "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

@test "INPUT_YAMLLINT_COMMENT: set true in PR scenario without lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/single_files/file2.yml"

  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  INPUT_YAMLLINT_COMMENT="true" \
  GITHUB_EVENT_PATH="/tmp/" \
  GITHUB_EVENT_NAME="pull_request" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -vq -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 0 ]]
}

### disabled (0,false)
@test "INPUT_YAMLLINT_COMMENT: set 0 in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/single_files/file1.yml"

  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  INPUT_YAMLLINT_COMMENT="0" \
  GITHUB_EVENT_PATH="/tmp/" \
  GITHUB_EVENT_NAME="pull_request" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

@test "INPUT_YAMLLINT_COMMENT: set false in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/single_files/file1.yml"

  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  INPUT_YAMLLINT_COMMENT="false" \
  GITHUB_EVENT_PATH="/tmp/" \
  GITHUB_EVENT_NAME="pull_request" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

### disabled (empty,notset)
@test "INPUT_YAMLLINT_COMMENT: set empty in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/single_files/file1.yml"

  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  INPUT_YAMLLINT_COMMENT="" \
  GITHUB_EVENT_PATH="/tmp/" \
  GITHUB_EVENT_NAME="pull_request" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

@test "INPUT_YAMLLINT_COMMENT: not set in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="${ROOT_DIR}/tests/data/single_files/file1.yml"

  run env \
  INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  GITHUB_EVENT_PATH="/tmp/" \
  GITHUB_EVENT_NAME="pull_request" \
  "${ROOT_DIR}/src/entrypoint.sh"

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}
