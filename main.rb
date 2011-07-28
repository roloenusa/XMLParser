#!/usr/bin/env ruby
require 'rubygems'  # not necessary for Ruby 1.9
require 'net/http'
require 'rexml/document'

require 'sinatra'
require 'haml'
require 'uri'

get '/' do 
    
  haml :index
end

post '/' do
  @endpoint = params[:endpoint]
  @method = params[:method]
  url = URI.parse(@endpoint)
  query = url.path + ("?#{url.query}" unless url.query.nil?)
  
  if  @method == "POST"
    request = Net::HTTP::Post.new(query)
    request.body = params[:xml].strip
  else
    request = Net::HTTP::Get.new(query)
  end
  
  response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
  xml = response.body
  
  doc, posts = REXML::Document.new(xml), []
    
  @xmlrequest = params[:xml].strip
  @xmlresponse = doc
  
  puts XmlExplorerOut doc
  puts "URL= #{url}"
  puts "Scheme=   #{url.scheme}"
  puts "Userinfo= #{url.userinfo}"
  puts "Host=     #{url.host}"
  puts "Port=     #{url.port}"
  puts "Registry= #{url.registry}"
  puts "Path=     #{url.path}"
  puts "Opaque=   #{url.opaque}"
  puts "Query=    #{url.query}"
  puts "Fragment= #{url.fragment}"
  
  # Print the entire thing
  # puts Net::HTTP.get_print url
 
  haml :index
end


get '/stress' do 

  haml :stress
end

post '/stress' do 

  @endpoint = params[:endpoint]
  @cycle = params[:cycles].to_i
  
  
  url = URI.parse(@endpoint)
  request = Net::HTTP::Post.new(url.path)
  request.body = params[:xml].strip
  
  response = []
  @responseTime= []
  @cycle.times do 
    @responseTime << time do
      response << Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    end
  end
  
  response.each do |c1|
    response.each do |c2|
      if c1.body != c2.body
        @error = "Not all the responses are the same!\n"
        @error = @error + "Response at index = #{response.index(c1)}\n"
        @error = @error + c1
        @error = @error + "Response at index = #{response.index(c2)}\n"
        @error = @error + c2
      end
    end
  end
  
  # xml = response.body
  # doc, posts = REXML::Document.new(xml), []
   
  @xmlrequest = params[:xml].strip
  #@xmlresponse = doc  
  
  haml :stress
end

get '/list' do
  orgPath = Dir.pwd
  Dir.chdir('./public/xml')
  @files = Dir.glob('*.xml')
  
  
  Dir.chdir(orgPath)  
  haml :list
end

#################
# Functions
#################

def XmlExplorerOut doc, level=0
  #white spacing
  ws = ""
  level.times { ws = ws + "  "}
  result = ""
  
  doc.elements.each do |p|
    # out = ws + p.name
    result = result + ws + p.name
 
    p.attributes.each do |key, value|
      #out = out + " " + "#{key}=\"#{value}\""
      result = result + " " + "#{key}=\"#{value}\""
    end   
    #puts out
    result = result + "\n"
    
    if !p.text.nil? && !p.text.strip.empty?
      #puts ws + "=> " + p.text
      result = result + ws + "=> " + p.text + "\n"
    end
   
    if !p.children.nil?
      result = result + XmlExplorerOut(p, level+1)
    end
  end
  
  result
end 

def XmlExplorer doc  
  doc.elements.each do |p|
    puts p.name
    
    p.attributes.each do |key, value|
      puts "\t#{key}=\"#{value}\""
    end
    
    XmlExplorer p
  end
end 

def FindKeyValuePair doc, pair = {}
  doc.elements.each do |p|
    if p.name == "entry"
      key, value = ""
      p.elements.each("key/string") do |v|
        key = v.attributes["value"]
      end
      
      p.elements.each("value/string") do |v|
        value = v.attributes["value"]
      end
      
      pair[key] = value
    end
    
    FindKeyValuePair p, pair
  end
  
  pair
end

def time
  start = Time.now
  yield
  Time.now - start
end
