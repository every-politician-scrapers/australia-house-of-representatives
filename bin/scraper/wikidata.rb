#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/wikidata_query'

# TODO: Add party
query = <<SPARQL
  SELECT (STRAFTER(STR(?item), STR(wd:)) AS ?wdid) ?name ?constituency
  WHERE {
    ?item p:P39 ?ps .
    ?ps ps:P39 wd:Q18912794 ; pq:P580 ?start .
    OPTIONAL { ?ps pq:P582 ?end }
    FILTER(!BOUND(?end) || ?end > NOW())

    OPTIONAL {
      ?ps pq:P768 ?district .
      OPTIONAL { ?district rdfs:label ?districtLabel FILTER(LANG(?districtLabel) = "en") }

      OPTIONAL {
        ?district wdt:P131 ?state .
        OPTIONAL { ?state rdfs:label ?stateLabel FILTER(LANG(?stateLabel) = "en") }
      }
    }

    OPTIONAL { ?ps prov:wasDerivedFrom/pr:P1810 ?sourceName }
    OPTIONAL { ?item rdfs:label ?enLabel FILTER(LANG(?enLabel) = "en") }
    BIND(COALESCE(?sourceName, ?enLabel) AS ?name)

    BIND(CONCAT(?districtLabel, ", ", ?stateLabel) AS ?constituency)
  }
  ORDER BY ?name
SPARQL

puts EveryPoliticianScraper::WikidataQuery.new(query, 'every-politican-scrapers/australia-house-of-representatives').csv
