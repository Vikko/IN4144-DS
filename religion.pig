--REGISTER hdfs://hathi-surfsara/user/TUD-DS02/lib/jwat-common-1.0.0.jar;
--REGISTER hdfs://hathi-surfsara/user/TUD-DS02/lib/jwat-gzip-1.0.0.jar;
--REGISTER hdfs://hathi-surfsara/user/TUD-DS02/lib/jwat-warc-1.0.0.jar;
--REGISTER hdfs://hathi-surfsara/user/TUD-DS02/lib/warcutils-1.2.jar;

REGISTER /home/naward/IN4144/lib/jwat-common-1.0.0.jar;
REGISTER /home/naward/IN4144/lib/jwat-gzip-1.0.0.jar;
REGISTER /home/naward/IN4144/lib/jwat-warc-1.0.0.jar;
REGISTER /home/naward/IN4144/warcutils/target/warcutils-1.2.jar;

-- DEFINE WarcFileLoader nl.surfsara.warcutils.pig.WarcSequenceFileLoader();
DEFINE WarcFileLoader nl.surfsara.warcutils.pig.WarcFileLoader();

-- Load data
-- test/sample/sample.warc 						--Small file, to check syntax locally
-- test/warc/*								--Single dataframe, to check output locally
-- /data/public/common-crawl/crawl-data/CC-TEST-2014-10/*/*/warc/* 	--Test set on the cluster
-- /data/public/common-crawl/crawl-data/CC-MAIN-2014-10/*/*/warc/* 	--Full set on the cluster
meta = LOAD '/data/public/common-crawl/crawl-data/CC-MAIN-2014-10/*/*/warc/*' USING WarcFileLoader AS (page_url, length, type, content);

-- Only accept text content types
meta = FILTER meta BY (SUBSTRING(type,0,4) == 'text') OR (type == 'application/pdf') OR (type == 'application/text');

-- Filter on God
filtered = FILTER meta BY LOWER(content) matches '.*(god|الله|θεός|dios|dieu|dio|deus|gott|gud|allah|shén|神|kami|ゴッド).*';
--filtered = FILTER meta BY LOWER(content) matches '.*(god).*';

--Extract regex
tlds = FOREACH meta GENERATE
       	REGEX_EXTRACT(LOWER(page_url), '(.*)://([a-z0-9-]*)\\.([a-z]+)/(.*)', 3) AS tld;
tlds = FOREACH tlds GENERATE (tld IS NOT NULL ? tld : 'unknown') as tld;
tlds_f = FOREACH filtered GENERATE 
	REGEX_EXTRACT(LOWER(page_url), '(.*)://([a-z0-9-]*)\\.([a-z]+)/(.*)', 3) AS tld;
tlds_f = FOREACH tlds_f GENERATE (tld IS NOT NULL ? tld : 'unknown') as tld;

-- Group and combine tlds
grouped = GROUP tlds BY tld;
result = FOREACH grouped GENERATE group as tld, COUNT(tlds.tld) AS count;
grouped_f = GROUP tlds_f BY tld;
result_f = FOREACH grouped_f GENERATE group as tld, COUNT(tlds_f.tld) AS count;
combined = JOIN result BY tld FULL, result_f BY tld;

--Order and store result
final = FOREACH combined GENERATE result::tld AS tld, result::count AS total, 
	(result_f::count IS NOT NULL ? result_f::count : 0) AS hit;
final = FOREACH final GENERATE *, (float)hit/total AS ratio;
ordered = ORDER final BY ratio DESC;
STORE ordered INTO 'results' USING PigStorage();
