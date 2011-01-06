# -*- coding: utf-8 -*-
#
# itunes_app_quote.rb - embeded App info from itune url.
#
# Copyright (C) 2011, tamoot <tamoot+tdiary@gmail.com>
# You can redistribute it and/or modify it under GPL2.
#
# usage:
#    <%= itunes_app_quote "url" %>
#

require 'kconv'
require 'open-uri'

def itunes_app_quote(url)
   begin
      xml = open(url).read
      
      img_src = xml.scan(/<img src="(http:\/\/.+\.175x175-75\.jpg)/).flatten.first
      
      h1      = xml.scan(/<h1>([^<>]+)<\/h1>/).flatten.first
      h1      = h1.to_s.toutf8.tosjis if title
      
      price   = xml.scan(/<div class="price">[^\\][^\\]([^<>]+)<\/div>/).flatten.first
      price   = '0' unless price =~ /\d+/
      
      #
      # te nu ki
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
      
      date    = detail[0].to_s.toutf8
      version = detail[1].to_s.toutf8
      lang    = detail[2].to_s.toutf8
      seller  = detail[3].to_s.toutf8
      requirement = detail[4].to_s.toutf8

      if img_src && h1 && price
         # use amazon-detail ss
         return <<APPHTML
<div class="amazon-detail">
    <a href="#{url}">
    <img src="#{img_src}" alt="#{h1.toutf8}" width="128" height="128" class="amazon-detail left">
    <div class="amazon-detail-desc">
       <span class="amazon-title">#{h1.toutf8}</span><br>
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
      end

   rescue Exception => e
      # do nothing.
      
   end

   # link for given url
   return %Q|<p><a href="#{url}">#{url}</a></p>|
end
