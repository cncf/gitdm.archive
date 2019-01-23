#!/bin/sh
mkdir ~/dev/grpc/ 2>/dev/null
# This list is from `cncf/velocity`:`BigQuery/query_cncf_repos.sql`
cd ~/dev/grpc || exit 1
git clone https://github.com/grpc/grpc.git || exit 1
git clone https://github.com/grpc/grpc-common.git || exit 1
git clone https://github.com/grpc/grpc-contrib.git || exit 1
git clone https://github.com/grpc/grpc-docker-library.git || exit 1
git clone https://github.com/grpc/grpc-experiments.git || exit 1
git clone https://github.com/grpc/grpc-go.git || exit 1
git clone https://github.com/grpc/grpc-haskell.git || exit 1
git clone https://github.com/grpc/grpc-java.git || exit 1
git clone https://github.com/grpc/grpc-swift.git || exit 1
git clone https://github.com/grpc/grpc.github.io.git || exit 1
git clone https://github.com/grpc/homebrew-grpc.git || exit 1
git clone https://github.com/grpc/proposal.git || exit 1
git clone https://github.com/grpc-ecosystem/go-grpc-middleware.git || exit 1
git clone https://github.com/grpc-ecosystem/go-grpc-prometheus.git || exit 1
git clone https://github.com/grpc-ecosystem/grift.git || exit 1
git clone https://github.com/grpc-ecosystem/grpc-exchange-o-gram.git || exit 1
git clone https://github.com/grpc-ecosystem/grpc-gateway.git || exit 1
git clone https://github.com/grpc-ecosystem/grpc-httpjson-transcoding.git || exit 1
git clone https://github.com/grpc-ecosystem/grpc-opentracing.git || exit 1
git clone https://github.com/grpc-ecosystem/grpc-simon-says.git || exit 1
git clone https://github.com/grpc-ecosystem/java-grpc-prometheus.git || exit 1
git clone https://github.com/grpc-ecosystem/meetup-kit.git || exit 1
git clone https://github.com/grpc-ecosystem/polyglot.git || exit 1
echo "All gRPC repos cloned"
