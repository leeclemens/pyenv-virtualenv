#!/usr/bin/env bats

load test_helper

setup() {
  export PYENV_ROOT="${TMP}/pyenv"
}

create_version() {
  mkdir -p "${PYENV_ROOT}/versions/$1/bin"
  touch "${PYENV_ROOT}/versions/$1/bin/python"
  chmod +x "${PYENV_ROOT}/versions/$1/bin/python"
}

remove_version() {
  rm -fr "${PYENV_ROOT}/versions/$1"
}

create_virtualenv() {
  create_version "$@"
  touch "${PYENV_ROOT}/versions/$1/bin/activate"
}

remove_virtualenv() {
  remove_version "$@"
}

@test "display prefix with using sys.real_prefix" {
  stub pyenv-version-name "echo venv27"
  stub pyenv-prefix "venv27 : echo \"${PYENV_ROOT}/versions/venv27\""
  stub pyenv-exec "echo \"${PYENV_ROOT}/versions/2.7.6\""
  create_virtualenv "venv27"

  PYENV_VERSION="venv27" run pyenv-virtualenv-prefix

  unstub pyenv-version-name
  unstub pyenv-prefix
  unstub pyenv-exec
  remove_virtualenv "venv27"

  assert_success
  assert_output <<OUT
${PYENV_ROOT}/versions/2.7.6
OUT
}

@test "display prefixes with using sys.real_prefix" {
  stub pyenv-version-name "echo venv27:venv32"
  stub pyenv-prefix "venv27 : echo \"${PYENV_ROOT}/versions/venv27\"" \
                    "venv32 : echo \"${PYENV_ROOT}/versions/venv32\""
  stub pyenv-exec "echo \"${PYENV_ROOT}/versions/2.7.6\"" \
                  "echo \"${PYENV_ROOT}/versions/3.2.1\""
  create_virtualenv "venv27"
  create_virtualenv "venv32"

  PYENV_VERSION="venv27:venv32" run pyenv-virtualenv-prefix

  unstub pyenv-version-name
  unstub pyenv-prefix
  unstub pyenv-exec
  remove_virtualenv "venv27"
  remove_virtualenv "venv32"

  assert_success
  assert_output <<OUT
${PYENV_ROOT}/versions/2.7.6:${PYENV_ROOT}/versions/3.2.1
OUT
}

@test "display prefix with using sys.base_prefix" {
  stub pyenv-version-name "echo venv33"
  stub pyenv-prefix "venv33 : echo \"${PYENV_ROOT}/versions/venv33\""
  stub pyenv-exec "false" \
                  "echo \"${PYENV_ROOT}/versions/3.3.3\""
  create_virtualenv "venv33"

  PYENV_VERSION="venv33" run pyenv-virtualenv-prefix

  unstub pyenv-version-name
  unstub pyenv-prefix
  unstub pyenv-exec
  remove_virtualenv "venv33"

  assert_success
  assert_output <<OUT
${PYENV_ROOT}/versions/3.3.3
OUT
}

@test "display prefixes with using sys.base_prefix" {
  stub pyenv-version-name "echo venv33:venv34"
  stub pyenv-prefix "venv33 : echo \"${PYENV_ROOT}/versions/venv33\"" \
                    "venv34 : echo \"${PYENV_ROOT}/versions/venv34\""
  stub pyenv-exec "false" \
                  "echo \"${PYENV_ROOT}/versions/3.3.3\"" \
                  "false" \
                  "echo \"${PYENV_ROOT}/versions/3.4.0\""
  create_virtualenv "venv33"
  create_virtualenv "venv34"

  PYENV_VERSION="venv33:venv34" run pyenv-virtualenv-prefix

  unstub pyenv-version-name
  unstub pyenv-prefix
  unstub pyenv-exec
  remove_virtualenv "venv33"
  remove_virtualenv "venv34"

  assert_success
  assert_output <<OUT
${PYENV_ROOT}/versions/3.3.3:${PYENV_ROOT}/versions/3.4.0
OUT
}

@test "should fail if the version is the system" {
  stub pyenv-version-name "echo system"

  PYENV_VERSION="system" run pyenv-virtualenv-prefix

  unstub pyenv-version-name

  assert_failure
  assert_output <<OUT
pyenv-virtualenv: version \`system' is not a virtualenv
OUT
}

@test "should fail if the version is not a virtualenv" {
  stub pyenv-version-name "echo 3.4.0"
  stub pyenv-prefix "3.4.0 : echo \"${PYENV_ROOT}/versions/3.4.0\""
  create_version "3.4.0"

  PYENV_VERSION="3.4.0" run pyenv-virtualenv-prefix

  unstub pyenv-version-name
  unstub pyenv-prefix
  remove_version "3.4.0"

  assert_failure
  assert_output <<OUT
pyenv-virtualenv: version \`3.4.0' is not a virtualenv
OUT
}

@test "should fail if one of the versions is not a virtualenv" {
  stub pyenv-version-name "echo venv33:3.4.0"
  stub pyenv-prefix "venv33 : echo \"${PYENV_ROOT}/versions/venv33\"" \
                    "3.4.0 : echo \"${PYENV_ROOT}/versions/3.4.0\""
  stub pyenv-exec "false" \
                  "echo \"${PYENV_ROOT}/versions/3.3.3\""
  create_virtualenv "venv33"
  create_version "3.4.0"

  PYENV_VERSION="venv33:3.4.0" run pyenv-virtualenv-prefix

  unstub pyenv-version-name
  unstub pyenv-prefix
  unstub pyenv-exec
  remove_virtualenv "venv33"
  remove_version "3.4.0"

  assert_failure
  assert_output <<OUT
pyenv-virtualenv: version \`3.4.0' is not a virtualenv
OUT
}


