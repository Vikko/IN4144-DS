# IN4144 - Data Science

## Introduction
Nowadays a big part of the society's knowledge is driven by media. We're informed by the news and papers of big happenings around the globe and prejudice populations of certain countries. All this information we receive is filtered and the thing we see might actually not be fully accurate. 
To get an idea of the fanatism in religion, which is known to be the main cause of most wars and conflicts, religiosity is measured worldwide by comparing references to deities on websites to their origin.

## Design
As pointed out by the instructor, it might become a problem to map the location of a website. There is no information in the meta data of a WARC record that leads to the geolocation of the content. IP adresses can be used to find the location of a server by cross referencing a lookup table with IP ranges, but a more simple approach to look at the top domain level to see if there is a country code. To start of simple I decided to go with TLD that can be extracted by a simple regex and focus on the extraction of religious terms instead.
To keep a flexible agile design I dediced to give it a try with Pig Latin. This would not guarantee the best possible run time, but that is not something that is required for a one-time run only, the possibility to easily adapt is more important.
The original idea of the pig script was to get the URL and full content (payload) of a website, narrow the urls down to their TLDs, then mark if they had a reference to god in their payload and count the total and the marked websites per TLD group. 

## Implementation
Prior to the use of pig, norvig's warcutils package needed to be adapted to read and extract the required data to be used in pig latin. The documentation was very poor on this so it took me a while to find out how exactly those data structures were incorporated in this package, as well as getting libraries linked and getting it to compile.
In the first implementation of the pig script I generated a field 'marked' that used a regex on the payload to detect words to set a field, then passed on the tld together with that mark for grouping. Although it sounded like a solid plan, in practice it took a lot of time to process. 
My first guess was that the regex would not perform well on huge strings, so to reduce that I implemented a filter that got rid of all non-text content types to avoid searching multiple kilobytes of an image for a text reference. This did not resolve the issue, so I tried moving the regex into the Java function. This would heavily sacrifice flexibility, but scanning the content line by line instead of a whole and breaking when a reference to a deity was found could be a great speedup. Unfortunately the performance of this approach was even worse!
My final and succesfull try was *filtering* with the regex on the full content, this performed quite well.
To keep the full list of domains and their count together with the filtered list, this means the datastream was duplicated at this point. In the script its visible that the same operations are applied to two variables each time, one being original, one being filtered. In the end those two datastreams are combined again for comparison and to calculate a ratio.
Sidenote on the final join step: Before joining nested annotation is used source.variable, but after joining a new name is generated in the format source::variable. I've spend a lot of time figuring out why my script did not work as it did only return 'Error 0' which is not very helpful.

## Usage 
To run this script you first need to compile the jar file.
```
cd warcutils
mvn package
```
This builds the jar in the warcutile/target directory.
Make sure the built library and the jwat libraries are linked in the script
```
REGISTER /home/naward/IN4144/lib/jwat-common-1.0.0.jar;
REGISTER /home/naward/IN4144/lib/jwat-gzip-1.0.0.jar;
REGISTER /home/naward/IN4144/lib/jwat-warc-1.0.0.jar;
REGISTER /home/naward/IN4144/warcutils/target/warcutils-1.2.jar;
```
The pigscript can be run with `pig -x local religious.pig`
the results will end up in the `./results/` directory

The search criteria are fully defined by the regex in the script, so instead of searching for 'God' in various languages, it is also possible to do a search on certain names, phone numbers or other patterns that can be described in Regex.

## Results
The results of the run on the full cluster, which took approx. 12 hours,  have been copied to [results.txt](https://github.com/Vikko/IN4144-DS/blob/master/results.txt). They are not filtered as post processing so they still contain mismatches on TLD like 'plumbing' and 'kitchen'.

| TLD | Total  | Hits   | Ratio     |
| --- |:------:|:------:| ---------:|
| au  | 547    | 533    | 0.9744058 |
| fm  | 664072 | 612642 | 0.9225536 |
| bm  |	2736   | 2436   | 0.8903509 |
| af  | 555    | 480    | 0.8648649 |
| ba  | 4965   | 4206   | 0.8471299 |

The top 5 of records that contain at least 500 sites already shows some interesting things. Out of 547 Australian websites, 97.4% contained the word 'God', followed by Micronesia, Bermuda, Afghanistan and Bosnia-Herzegovina who all have an above 80% hit on the regex. Due to the simple approach of filtering the full content on a string and taking a TLD instead of trying to parse a location, these numbers are not very trustworthy. By applying more specified filters that, for instance, just target social media the accuracy could be increased. In addition to that it would probably be helpfull if a bigger list of religious references is used instead of a simple string containing the word 'God' in multiple languages. References to prophets or teachers like in Buddhism should be taken into account as well.

## Final remarks
Big data is still a hard topic to work with. It's relatively new, technologies are complex and not too broadly used, this makes it harder to gain knowledge. Apache Pig is a really nice tool to generate the more complex map-reduce jobs without going deep into detail with them. This certainly lowers the bar to step into the world of big data.

I started off this project a bit more ambitious then I ended, the plan was to create a script that could handle a complex filter to separate religious from other sites and extract their location based on IP ranges and meta information. Even while warned, the first steps already took more time then expected. In addition my only other teammate notified me after a few weeks that she didn't have time to do anything and was dropping the course. This forced me to simplify it even more and the result is a simple, but flexible word filter with a simple location estimation. I think this would be a good start for any big data project since its flexibility is a good basis for any big data topic.
