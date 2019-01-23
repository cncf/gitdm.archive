#!/bin/sh
mkdir ~/dev/opentracing/ 2>/dev/null
# This list is from `cncf/velocity`:`BigQuery/query_cncf_repos.sql`
cd ~/dev/opentracing || exit 1
git clone https://github.com/opentracing/basictracer-csharp.git || exit 1
git clone https://github.com/opentracing/basictracer-go.git || exit 1
git clone https://github.com/opentracing/basictracer-javascript.git || exit 1
git clone https://github.com/opentracing/basictracer-python.git || exit 1
git clone https://github.com/opentracing/contrib.git || exit 1
git clone https://github.com/opentracing/opentracing-cpp.git || exit 1
git clone https://github.com/opentracing/opentracing-csharp.git || exit 1
git clone https://github.com/opentracing/opentracing-go.git || exit 1
git clone https://github.com/opentracing/opentracing-java.git || exit 1
git clone https://github.com/opentracing/opentracing-javascript.git || exit 1
git clone https://github.com/opentracing/opentracing-objc.git || exit 1
git clone https://github.com/opentracing/opentracing-python.git || exit 1
git clone https://github.com/opentracing/opentracing-ruby.git || exit 1
git clone https://github.com/opentracing/opentracing.github.io.git || exit 1
git clone https://github.com/opentracing/opentracing.io.git || exit 1
git clone https://github.com/opentracing/specification.git || exit 1
echo "All OpenTracing repos cloned"
