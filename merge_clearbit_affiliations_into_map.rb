#read developer_affiliation_lookup.csv
#read email-map
#remove company suffixes such as Inc.,
#create map entries and insert appropriately
#if email found and has something other than self or notfound but new data has something, overwrite
#if data record is new, add
require 'csv'
require 'pry'

