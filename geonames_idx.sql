create index geonames_name_idx ON geonames using btree(name);
create index geonames_asciiname_idx ON geonames using btree(asciiname);
create index geonames_countrycode_idx ON geonames using btree(countrycode);
create index geonames_population_idx ON geonames using btree(population);
create index geonames_fcl_idx ON geonames using btree(fcl);
create index geonames_lower_name_idx ON geonames using btree(lower(name));
create index geonames_lower_asciiname_idx ON geonames using btree(lower(asciiname));

create index geonames_geonameid_idx ON alternatenames using btree(geonameid);
create index geonames_altname_idx ON alternatenames using btree(altname);
create index geonames_lower_altname_idx ON alternatenames using btree(lower(altname));
