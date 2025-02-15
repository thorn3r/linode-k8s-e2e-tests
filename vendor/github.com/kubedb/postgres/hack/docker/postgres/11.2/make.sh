#!/bin/bash
set -xeou pipefail

GOPATH=$(go env GOPATH)
REPO_ROOT=$GOPATH/src/github.com/kubedb/postgres

source "$REPO_ROOT/hack/libbuild/common/lib.sh"
source "$REPO_ROOT/hack/libbuild/common/kubedb_image.sh"

DOCKER_REGISTRY=${DOCKER_REGISTRY:-kubedb}

IMG=postgres
DB_VERSION=11.2
TAG="$DB_VERSION"

WALG_VER=${WALG_VER:-0.2.9-ac}

DIST="$REPO_ROOT/dist"
mkdir -p "$DIST"

build_binary() {
  pushd $REPO_ROOT
  ./hack/builddeps.sh
  ./hack/make.py build pg-operator
  popd
}

build_docker() {
  pushd "$REPO_ROOT/hack/docker/postgres/$DB_VERSION"

  # Download wal-g
  wget https://github.com/kubedb/wal-g/releases/download/${WALG_VER}/wal-g-alpine-amd64
  chmod +x wal-g-alpine-amd64
  mv wal-g-alpine-amd64 wal-g

  # Copy pg-operator
  cp "$DIST/pg-operator/pg-operator-alpine-amd64" pg-operator
  chmod 755 pg-operator

  local cmd="docker build --pull -t $DOCKER_REGISTRY/$IMG:$TAG ."
  echo $cmd; $cmd

  rm wal-g pg-operator
  popd
}

build() {
  build_binary
  build_docker
}

binary_repo $@
