#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'

require 'open-uri/cached'

class Legislature
  # details for an individual member
  class Member < Scraped::HTML
    field :id do
      url.split('=').last
    end

    PREFIXES = %w[Hon Mr Mrs Ms Dr].freeze
    SUFFIXES = %w[MP OAM AM QC].freeze

    field :name do
      SUFFIXES.reduce(unprefixed_name) { |current, suffix| current.sub(/#{suffix},?\s?$/, '').tidy }
    end

    field :party do
      noko.xpath('.//dt[text()="Party"]/following-sibling::dd[1]').text
    end

    field :constituency do
      noko.xpath('.//dt[text()="For"]/following-sibling::dd[1]').text
    end

    private

    def url
      noko.css('h4 a/@href').text
    end

    def full_name
      noko.css('h4').text.tidy
    end

    def unprefixed_name
      PREFIXES.reduce(full_name) { |current, prefix| current.sub("#{prefix} ", '') }
    end
  end

  # The page listing all the members
  class Members < Scraped::HTML
    decorator Scraped::Response::Decorator::CleanUrls

    field :members do
      noko.css('.search-filter-results .row').map { |mp| fragment(mp => Member).to_h }
    end
  end
end

# TODO: have ScraperData handle multiple URLs
urls = [
  'https://www.aph.gov.au/Senators_and_Members/Parliamentarian_Search_Results?q=&mem=1&par=-1&gen=0&ps=96&st=1',
  'https://www.aph.gov.au/Senators_and_Members/Parliamentarian_Search_Results?page=2&q=&mem=1&par=-1&gen=0&ps=96&st=1'
]

# We need to remove the header row from the second CSV
csvs = urls.map { |url| EveryPoliticianScraper::ScraperData.new(url).csv.lines }
puts (csvs[0] + csvs[1].drop(1)).join
