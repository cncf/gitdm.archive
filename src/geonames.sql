drop table if exists geonames;
create table geonames(
  geonameid bigint not null,
  name character varying(200) not null,
  asciiname character varying(200) not null,
-- alternatenames text,
  latitude double precision not null,
  longitude double precision not null,
  fcl char(1) not null,
  fco character varying(10) not null,
  countrycode char(2) not null,
--  cc2 character varying(200) not null,
  ac1 character varying(20) not null,
  ac2 character varying(80) not null,
  ac3 character varying(20) not null,
  ac4 character varying(20) not null,
  population bigint not null,
  elevation int not null,
--  dem int not null,
  tz character varying(40) not null,
--  modification date not null,
  primary key(geonameid)
);
alter table geonames owner to gha_admin;

drop table if exists alternatenames;
create table alternatenames(
  geonameid bigint not null,
  altname text not null,
  primary key(geonameid, altname)
);
alter table alternatenames owner to gha_admin;
