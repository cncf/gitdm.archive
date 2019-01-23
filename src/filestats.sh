#!/bin/sh
ruby filestats.rb per_dirs/rel_v1.0.0_v1.1.0.csv per_dirs/rel_v1.0.0_v1.1.0_stats.csv
ruby filestats.rb per_dirs/rel_v1.1.0_v1.2.0.csv per_dirs/rel_v1.1.0_v1.2.0_stats.csv
ruby filestats.rb per_dirs/rel_v1.2.0_v1.3.0.csv per_dirs/rel_v1.2.0_v1.3.0_stats.csv
ruby filestats.rb per_dirs/rel_v1.3.0_v1.4.0.csv per_dirs/rel_v1.3.0_v1.4.0_stats.csv
ruby filestats.rb per_dirs/rel_v1.4.0_v1.5.0.csv per_dirs/rel_v1.4.0_v1.5.0_stats.csv
ruby filestats.rb per_dirs/rel_v1.5.0_v1.6.0.csv per_dirs/rel_v1.5.0_v1.6.0_stats.csv
ruby filestats.rb per_dirs/rel_v1.6.0_v1.7.0.csv per_dirs/rel_v1.6.0_v1.7.0_stats.csv
ruby filestats.rb per_dirs/all.csv per_dirs/all_stats.csv
