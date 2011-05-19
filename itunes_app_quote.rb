# -*- coding: utf-8 -*-
#
# itunes_app_quote.rb - Making link with image to iTunes.
#
# see label: #{@lang}/itunes_app_quote.rb
#
# Copyright (C) 2011, tamoot <tamoot+tdiary@gmail.com>
# You can redistribute it and/or modify it under GPL2.
#
# usage:
#    <%= itunes_app_quote "url" %>
#

require 'net/http'
require 'timeout'
require 'pstore'
require 'yaml/store'

def itunes_app_quote_yaml
   cache_path = @conf.cache_path || "#{@conf.data_path}cache"
   plugin_cache_dir = "#{cache_path}/itunes_app_quote"
   Dir::mkdir(plugin_cache_dir) unless File::directory?(plugin_cache_dir)
   "#{plugin_cache_dir}/data.yaml"
end

def get_itunes(url)
   xml = nil
   Net::HTTP.version_1_2
   px_host, px_port = ( @conf['proxy'] || '' ).split( /:/ )
   uri = URI::parse(url)
   timeout( 5 ) do
      xml = Net::HTTP::Proxy(px_host, px_port).start(uri.host, uri.port) do |http|
         response = http.get(uri.request_uri)
         response.body
      end
   end
   xml
end

def parse_itunes(xml)
   img_src = xml.scan(/<img src="(http:\/\/.+\.175x175-75\.jpg)/).flatten.first
   
   h1      = xml.scan(/<h1>([^<>]+)<\/h1>/).flatten.first
   h1      = h1.to_s.toutf8.tosjis if title
   
   price   = xml.scan(/<div class="price">[^\\][^\\]([^<>]+)<\/div>/).flatten.first
   price   = '0' unless price =~ /\d+/
      
   #
   # "te nu ki" regrep for REXML Error...
   #
   regrep_str = ''
   # date
   regrep_str << '<li class="release-date"><span class="label">[^<>]+<\/span>([^<>]+)<\/li>'
   # version
   regrep_str << '<li><span class="label">[^<>]+<\/span>[^<>]+<\/li><li>([^<>]+)<\/li>'
   # language
   regrep_str << '.*<li class="language"><span class="label">[^<>]+<\/span>([^<>]+)<\/li>'
   # seller
   regrep_str << '<li><span class="label">[^<>]+</span>([^<>]+)</li>'
   # requirements
   regrep_str << '.*<span class="app-requirements">[^<>]+<\/span>([^<>]+)<\/p>'
   regrep = /#{regrep_str}/
      
   detail = xml.scan(regrep).flatten
   [img_src, h1, price, detail, Time::now].flatten
end

def save_cache(url, detail)
   YAML::Store.new(itunes_app_quote_yaml).transaction do |db|
      db[url] = detail
   end
end

def get_from_cache(url)
   detail = nil
   YAML::Store.new(itunes_app_quote_yaml).transaction(true) do |db|
      detail = db[url]
   end
   raise StandardError.new("no cache") unless detail
   if detail.last
      raise StandardError.new("data expired") if Time::now - detail.last > 1 * 3600
   end
   detail
end

def itunes_app_quote(url)
   message  = nil
   backtrace = nil
   begin
      detail = nil
      begin
         detail = get_from_cache(url)
      rescue Exception => e
         xml    = get_itunes(url)
         detail = parse_itunes(xml)
         save_cache(url, detail)
      end
      
      img_src = @conf.to_native detail[0].to_s
      h1      = @conf.to_native detail[1].to_s
      price   = @conf.to_native detail[2].to_s
      date    = @conf.to_native detail[3].to_s
      version = @conf.to_native detail[4].to_s
      lang    = @conf.to_native detail[5].to_s
      seller  = @conf.to_native detail[6].to_s
      requirement = @conf.to_native detail[7].to_s

      if img_src && h1 && price
         # use amazon-detail ss
         return <<APPHTML
<div class="amazon-detail">
    <a href="#{url}">
    <img src="#{img_src}" alt="#{h1}" width="128" height="128" class="amazon-detail left">
    <div class="amazon-detail-desc">
       <span class="amazon-title">#{h1}</span><br>
       <span class="amazon-price">#{@label_date}: #{date}</span><br>
       <span class="amazon-price">#{@label_version}: #{version}</span><br>
       <span class="amazon-price">#{@label_price}: #{price} yen</span><br>
       <span class="amazon-price">#{@label_language}: #{lang}</span><br>
       <span class="amazon-price">#{@label_seller}: #{seller}</span><br>
       <span class="amazon-price">#{@label_requirement}: #{requirement}</span><br>
    </div>
    <br style="clear: left">
    </a>
</div>
APPHTML
      else
         raise StandardError.new("no data")
      end

   rescue Exception => e
      # do nothing.
      message = e.message      
      backtrace = e.backtrace.join("<br>")
   end

   # link for given url
   return %Q|<p><a href="#{url}">#{url}</a> #{h message}, #{h backtrace}</p>|
end

# Local Variables:
# mode: ruby
# indent-tabs-mode: t
# tab-width: 3
# ruby-indent-level: 3
# End:
# vim: ts=3

