create index geonames_name_idx on geonames using btree(name);
create index geonames_asciiname_idx on geonames using btree(asciiname);
create index geonames_countrycode_idx on geonames using btree(countrycode);
create index geonames_population_idx on geonames using btree(population);
create index geonames_fcl_idx on geonames using btree(fcl);
create index geonames_lower_name_idx on geonames using btree(lower(name));
create index geonames_lower_asciiname_idx on geonames using btree(lower(asciiname));

create index geonames_geonameid_idx on alternatenames using btree(geonameid);
create index geonames_altname_idx on alternatenames using btree(altname);
create index geonames_lower_altname_idx on alternatenames using btree(lower(altname));
