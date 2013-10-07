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

#BASE_URL = "http://stackworld.herokuapp.com"
BASE_URL = "http://stormy-everglades-2242.herokuapp.com"
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
    self.links = options_hash[:links]
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
  room_name = page_doc.css('h1')[0].text.strip
  # 5. Get outbound links that we care about (room connections)
  links = page_doc.css('a')
  filtered_links = links.select do |link|
    link['href'] =~ /room\/\d+$/
  end

#  room_links = page_html.css('a').select { |link| link['href'] =~ /room\/\d*$/)



  # full_filtered_links = []
  # full_filtered_links << filtered_links.each do |link|
  #   "#{BASE_URL}" + link['href']
  # end
  # puts "filtered_links"
  # puts filtered_links
  # puts "full_filtered_links"
  # puts full_filtered_links


  # this works but may not be useful
#  puts "filtered_links"
#  puts filtered_links
  # filtered_links.map do |link|
  #   link['href'] = "#{BASE_URL}" + link['href']
  # end
  # puts "fuller filtered_links"
  # puts filtered_links

  # 6. Save the page info into a hash called $url_to_page which maps URLS to Page objects.
  linkstring = "#{BASE_URL}" + link
  # $url_to_page[linkstring] = Page.new({:url => linkstring, :title => room_name, :links => filtered_links})

  # 7. For each outbound link, call get_and_crawl_link(link)
  cur_page_links = []
  filtered_links.each do |filtered_link|
    link_href = ""
    link_href = BASE_URL + filtered_link['href']
    cur_page_links << link_href
    if !$visited_links.include?("#{BASE_URL}" + filtered_link['href'])
      # crawl_link("#{BASE_URL}" + filtered_link['href'])
      crawl_link(link_href)
    end
  end
  $url_to_page[linkstring] = Page.new({:url => linkstring, :title => room_name, :links => cur_page_links})




#   filtered_links.each do |filtered_link|
#     # if !$visited_links.include?("#{BASE_URL}" + link['href'])
#       # 6. Save the page info into a hash called $url_to_page which maps URLS to Page objects.
# #      linkstring = "#{BASE_URL}" + link['href']
#       linkstring = "#{BASE_URL}" + link
# #      puts "filtered_links"
# #      puts filtered_links

# #      $url_to_page[linkstring] = Page.new({:url => linkstring, :title => room_name, :links => "blah"})
#       $url_to_page[linkstring] = Page.new({:url => linkstring, :title => room_name, :links => filtered_links})
# #      $url_to_page[linkstring] = Page.new({:url => linkstring, :title => room_name})

#       # 7. For each outbound link, call get_and_crawl_link(link)
# #    if !$visited_links.include?("#{BASE_URL}" + link['href'])
#       # crawl_link("#{BASE_URL}" + link['href'])
#     if !$visited_links.include?("#{BASE_URL}" + filtered_link['href'])
#       crawl_link("#{BASE_URL}" + filtered_link['href'])
#     end
#   end

end

crawl_link(WORLD_START_URL)

puts "$visited_links"
puts $visited_links

puts "$url_to_page"
puts $url_to_page.to_s


# calling to .json
$nodes_array = []
$links_array = []

#$url_to_pages.each do |url, page_object|
# put a hash representing page_object into $nodes_array

# for each link in the page_object, find the corresponding page_object of that link, create a hash into the $links_array array
# source = page.index
# target link's page.index
#end

# $d3js_data = {
#   :nodes => $nodes_array,
#   :links => $links_array
# }.to_json

def convert_to_json
  ret = { :nodes => [], :links => [] }

  $url_to_page.each_with_index do |(url, page), i|
    page.index = i
    ret[:nodes] << { :name => page.title, :group => 1 }
  end

  $url_to_page.each_with_index do |(url, page), i|
    page.links.each do |link|
      ret[:links] << { :source => page.index, :target => $url_to_page[link].index, :value => 10 }
    end
  end

  ret.to_json

end

## Start Sinatra App here:

get '/' do
  erb :index
end

get '/world.json' do
  content_type :json
  $d3_hash
end

# get '/world.json' do
#   content_type :json
#   ## Render the hash that d3.js org needs:
#   ## This example hash represents two rooms that you can walk back and forth to each other (notice that they both have links to each other and that the links point to the nodes array)
#   example_data = { :nodes => [
#     { :name => "Room name", :group => 1 },
#     { :name => "Another room", :group => 1 }
#       ],
#     :links => [
#     { :source => 0, :target => 1 },
#     { :source => 1, :target => 0 }
#       ]
#   }

#   # return the example data as JSON when asked
#   example_data.to_json

# end
