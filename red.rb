#!/usr/bin/env ruby

require 'rubygems'
require 'uri'
require 'nokogiri'
require 'htmlcompressor'


def simplify_css(page, url, file_id)
  cssfile = "simplified#{file_id}.css"
  cssminfile = "simplified#{file_id}.min.css"

  ignore = [
  ]

  index = 0
  page.css('link[rel=stylesheet]').each do |css|
    href = css['href']
    if href[0..3] != 'http'
      href = '/' + href if href[0] != '/'
      href = url + href
    end
    filename = index.to_s.rjust(2, '0') + '_' + URI(href).path.split('/').last
    `cd var/old/css; wget --quiet -O #{filename} #{href}`
    if ignore.include? css['href']
      `cp var/old/css/#{filename} var/new/`
    else
      css.remove
    end
    index += 1
  end

  ignore = ignore.join(',')
  `cd var/new/; uncss -S #{ignore} #{url} > #{cssfile}`

  new_link = Nokogiri::XML::Node.new 'link', page
  new_link['rel'] = 'stylesheet'
  new_link['href'] = "/#{cssminfile}"
  new_link['media'] = 'all' # FIXME: may not all be for 'all media'
  new_link.parent = page.at_css('head')

  `cd var/new/; yuicompressor #{cssfile} > #{cssminfile}; rm #{cssfile}`
end

# FIXME: JS simplification is not working
# (ordering, probably, because there are inline scripts too)
#
def simplify_js(page)
  index = 0
  page.css('script[src]').each do |js|
    filename = index.to_s.rjust(2, '0') + '_' + URI(js['src']).path.split('/').last
    `cd var/old/js; wget --quiet -O #{filename} #{js['src']}`
    js.remove
    index += 1
  end

  `cat var/old/js/* > var/new/simplified.js`

  new_link = Nokogiri::XML::Node.new 'script', page
  new_link['src'] = '/simplified.js'
  new_link.parent = page.at_css('body')

  `cd var/new/; yuicompressor simplified.js > simplified.min.js`
end

if ARGV[0].nil?
  puts "Usage: mini.rb http://host.tld/path"
  exit
end
url = ARGV[0].downcase

pu = URI(url)
id = pu.path.gsub('/', '_').gsub(/\_$/, '')

puts "> Resetting var/"
`rm -fr var && mkdir -p var/{new,old/css,old/js}`

puts "> Fetching #{url}..."
`cd var/old; wget --quiet -O index.html #{url}`
page = Nokogiri::HTML(File.read('var/old/index.html'))

puts "> Simplifying CSS..."
simplify_css page, url, id
#simplify_js page, url

puts "> Removing comments..."
page.xpath('//comment()').each do |c|
  if (c.content !~ /\A(\[if|\<\!\[endif)/)
    c.remove()
  end
end

puts "> Removing unneeded meta headers..."
page.xpath('/html/head/meta[@name="generator"]').each do |c|
  c.remove()
end

puts "> Compressing HTML and saving file..."
File.open("var/new/index#{id}.html", 'w') { |f|
  f.write(HtmlCompressor::Compressor.new.compress(page.to_html))
}

puts "> All done!"

puts "> This gives:"
puts `du -sh var/old var/new`

#simplify_js page
