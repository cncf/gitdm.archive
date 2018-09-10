create index geonames_name_idx ON geonames using btree(name);
create index geonames_asciiname_idx ON geonames using btree(altname);
create index geonames_countrycode_idx ON geonames using btree(countrycode);
create index geonames_population_idx ON geonames using btree(population);
create index geonames_ac1_idx ON geonames using btree(ac1);
create index geonames_ac2_idx ON geonames using btree(ac2);
create index geonames_ac3_idx ON geonames using btree(ac3);
create index geonames_ac4_idx ON geonames using btree(ac4);
create index geonames_fcl_idx ON geonames using btree(fcl);
create index geonames_fco_idx ON geonames using btree(fco);

create index geonames_geonameid_idx ON alternatenames using btree(geonameid);
create index geonames_altname_idx ON alternatenames using btree(altname);
