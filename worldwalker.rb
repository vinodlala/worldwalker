require 'bundler'
Bundler.setup

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'mechanize'
require 'debugger'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'

BASE_URL = "http://stackworld.herokuapp.com"
WORLD_START_URL = "#{BASE_URL}/room/1"

require_relative 'environments'


class Page
  attr_accessor :url
  attr_accessor :title
  attr_accessor :links
  attr_accessor :pages
  attr_accessor :index

  def initialize(options_hash = {})
    self.url = options_hash[:url]
    self.title = options_hash[:title]
  end
end

# keyed by URL => Page
$url_to_page = {}

# two arrays for speed
$visited_links = []

def crawl_link(link, depth = 0)

  # 1. Get the page using open
  page_html = open(link)

  # 2. Add the page's URL to the visited links array
  if !$visited_links.include?(link)
    $visited_links << link
    puts link
  end

  # 3. Use Nokogiri to parse the page into a Nokogiri document
  page_doc = Nokogiri::HTML(page_html)

  # 4. Get any page information like room name
  room_name = page_doc.css('h1')[0].text

  # 5. Get outbound links that we care about (room connections)
  links = page_doc.css('a')
  filtered_links = links.select do |link|
    link['href'] =~ /room\/\d+$/
  end




  filtered_links.each do |link|
    if !$visited_links.include?("#{BASE_URL}" + link['href'])
  # # 6. Save the page information as a new Page object, put it into a
  # # hash called something like $url_to_page which maps URLS to the
  # # Page objects.
  # # $url_to_page << link['href']
      linkstring = "#{BASE_URL}" + link['href']
      $url_to_page[linkstring] = Page.new({:url => linkstring, :title => room_name})
#   $url_to_page << Page.new(:url => link['href'], :title => room_name)

  #   :links => links
  #   # :pages =
  #   # :index =

  # 7. For each outbound link, call get_and_crawl_link(link)
  # This method will keep calling itself until it's visited every
  # room on the site
      #linkstring = "#{BASE_URL}" + link['href']
      #puts linkstring
      crawl_link("#{BASE_URL}" + link['href'])
    end
  end

end

crawl_link(WORLD_START_URL)

## Start Sinatra App here:

get '/' do
  erb :index
end

get '/world.json' do
  content_type :json
  ## Render the hash that d3.js org needs:
  ## This example hash represents two rooms that you can walk back and forth to each other (notice that they both have links to each other and that the links point to the nodes array)
  example_data = { :nodes => [
    { :name => "Room name", :group => 1 },
    { :name => "Another room", :group => 1 }
      ],
    :links => [
    { :source => 0, :target => 1 },
    { :source => 1, :target => 0 }
      ]
  }

  # return the example data as JSON when asked
  example_data.to_json

end
