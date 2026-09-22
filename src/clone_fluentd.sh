#!/bin/sh
mkdir ~/dev/fluentd/ 2>/dev/null
# This list is from `cncf/velocity`:`BigQuery/query_cncf_repos.sql`
cd ~/dev/fluentd || exit 1
git clone https://github.com/fluent/NLog.Targets.Fluentd.git || exit 1
git clone https://github.com/fluent/fluent-bit.git || exit 1
git clone https://github.com/fluent/fluent-bit-docker-image.git || exit 1
git clone https://github.com/fluent/fluent-bit-docs.git || exit 1
git clone https://github.com/fluent/fluent-bit-go.git || exit 1
git clone https://github.com/fluent/fluent-bit-kubernetes-daemonset.git || exit 1
git clone https://github.com/fluent/fluent-logger-erlang.git || exit 1
git clone https://github.com/fluent/fluent-logger-golang.git || exit 1
git clone https://github.com/fluent/fluent-logger-java.git || exit 1
git clone https://github.com/fluent/fluent-logger-node.git || exit 1
git clone https://github.com/fluent/fluent-logger-perl.git || exit 1
git clone https://github.com/fluent/fluent-logger-php.git || exit 1
git clone https://github.com/fluent/fluent-logger-python.git || exit 1
git clone https://github.com/fluent/fluent-logger-ruby.git || exit 1
git clone https://github.com/fluent/fluent-logger-scala.git || exit 1
git clone https://github.com/fluent/fluent-plugin-flume.git || exit 1
git clone https://github.com/fluent/fluent-plugin-grok-parser.git || exit 1
git clone https://github.com/fluent/fluent-plugin-kafka.git || exit 1
git clone https://github.com/fluent/fluent-plugin-mongo.git || exit 1
git clone https://github.com/fluent/fluent-plugin-multiprocess.git || exit 1
git clone https://github.com/fluent/fluent-plugin-rewrite-tag-filter.git || exit 1
git clone https://github.com/fluent/fluent-plugin-s3.git || exit 1
git clone https://github.com/fluent/fluent-plugin-sql.git || exit 1
git clone https://github.com/fluent/fluent-plugin-webhdfs.git || exit 1
git clone https://github.com/fluent/fluent-plugin-windows-eventlog.git || exit 1
git clone https://github.com/fluent/fluentd.git || exit 1
git clone https://github.com/fluent/fluentd-docker-image.git || exit 1
git clone https://github.com/fluent/fluentd-docs.git || exit 1
git clone https://github.com/fluent/fluentd-forwarder.git || exit 1
git clone https://github.com/fluent/fluentd-kubernetes-daemonset.git || exit 1
git clone https://github.com/fluent/fluentd-ui.git || exit 1
git clone https://github.com/fluent/fluentd-website.git || exit 1
git clone https://github.com/fluent/serverengine.git || exit 1
echo "All Fluentd repos cloned"
