# Copyright (C) 2006-2008 by Sergio Pistone
# sergio_pistone@yahoo.com.ar
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

require File.expand_path( File.dirname( __FILE__ ) + "/formdata" )

require "net/http"
require "uri"

module HTTP

# 	@@user_agent = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2"
	@@user_agent = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.9) Gecko/20071110 Firefox/2.0.0.9"
# 	@@user_agent = "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12) Gecko/20080218 Firefox/2.0.0.12"

	@@proxy_url = nil
	@@proxy_excluded_urls = []
	@@proxy_reverse = false # if true, excluded_urls list becomes a list with the _only_ urls the proxy should be used for

	def HTTP.normalize_url( url, protocol="http" )
		url = url.strip()
		protocol_regexp = /^ *([^: ]+):\/+/
		md = protocol_regexp.match( url )
		return nil if md && md[1] != protocol
		url.gsub!( /\/+$/, "" )				# remove / at the end of the url
		url.gsub!( protocol_regexp, "" )	# remove the protocol part if there was one
		return "#{protocol}://#{url}"		# reinsert protocol part assuring protocol:// form
	end

	def HTTP.set_proxy_settings( proxy_url, excluded_urls=[], reverse=false )
		@@proxy_url = proxy_url ? HTTP.normalize_url( proxy_url, "http" ) : nil
		@@proxy_reverse = @@proxy_url ? reverse : false
		@@proxy_excluded_urls = []
		if @@proxy_url
			excluded_urls.each() do |url|
				url = normalize_url( url, "http" )
				@@proxy_excluded_urls.insert( -1, url ) if url && ! @@proxy_excluded_urls.include?( url )
			end
		end
	end

	def HTTP.get_proxy_settings()
		ret = [@@proxy_url ? @@proxy_url.dup : nil, [], @@proxy_reverse]
		@@proxy_excluded_urls.each() { |url| ret[1][ret[1].size] = url.dup  }
		return ret
	end

	# returns proxy_host, proxy_port, proxy_user, proxy_pass for given url
	def HTTP.get_url_proxy_settings( url )

		return nil, nil, nil, nil if ! @@proxy_url
		proxy = HTTP.parse_uri( @@proxy_url )
		return nil, nil, nil, nil if ! proxy.host
		proxy.port = 80 if ! proxy.port

		# check if given url should be treated specially
		exception = false
		@@proxy_excluded_urls.each() do |exception_url|
			if url.index( exception_url ) == 0
				exception = true
				break
			end
		end

		if exception && @@proxy_reverse || ! exception && ! @@proxy_reverse
			return proxy.host, proxy.port, proxy.user, proxy.password
		else
			return nil, nil, nil, nil
		end
	end

	def HTTP.parse_uri( uri )
		begin
			return URI.parse( uri )
		rescue URI::InvalidURIError
			return URI.parse( URI.escape( uri ) )
		end
	end

	def HTTP.fetch_page_get( url, headers=nil, follow=10 )
		begin

			p_url = HTTP.parse_uri( url )
			return nil, url if p_url.host == nil || p_url.port == nil || p_url.request_uri == nil
			proxy_host, proxy_port, proxy_user, proxy_pass = HTTP.get_url_proxy_settings( url )

			full_headers = {
				"User-Agent" => @@user_agent,
				"Referer" => "#{p_url.scheme}://#{p_url.host}",
			}
			full_headers.merge!( headers ) if headers

			http = Net::HTTP.new( p_url.host, p_url.port, proxy_host, proxy_port, proxy_user, proxy_pass )
			response = http.request_get( p_url.request_uri, full_headers )

			case response
				when Net::HTTPSuccess
				when Net::HTTPRedirection, Net::HTTPFound
					if follow == 0
						response = nil
					elsif follow > 0
						response, url = HTTP.fetch_page_get( response["location"], nil, follow-1 )
					end
				else
					response = nil
			end

			return response, url

		rescue Errno::ETIMEDOUT, Errno::EBADF, EOFError => e
			raise TimeoutError.new( e.to_s )
		end
	end

	def HTTP.fetch_page_post( url, params, headers=nil, follow=10 )
		begin
			p_url = HTTP.parse_uri( url )
			return nil, url if p_url.host == nil || p_url.port == nil || p_url.request_uri == nil
			proxy_host, proxy_port, proxy_user, proxy_pass = HTTP.get_url_proxy_settings( url )

			data, full_headers = URLEncodedFormData.prepare_query( params )
			full_headers["User-Agent"] = @@user_agent
			full_headers["Referer"] = "#{p_url.scheme}://#{p_url.host}"
			full_headers.merge!( headers ) if headers

			http = Net::HTTP.new( p_url.host, p_url.port, proxy_host, proxy_port, proxy_user, proxy_pass )
			response = http.request_post( p_url.request_uri, data, full_headers )

			case response
				when Net::HTTPSuccess
				when Net::HTTPRedirection, Net::HTTPFound
					if follow == 0
						response = nil
					elsif follow > 0
						response, url = HTTP.fetch_page_get( response["location"], nil, follow-1 )
					end
				else
					response = nil
			end

			return response, url

		rescue Errno::ETIMEDOUT, Errno::EBADF, EOFError => e
			raise TimeoutError.new( e.to_s )
		end
	end

	def HTTP.fetch_page_post_form_multipart( url, params, headers=nil, follow=10 )
		begin

			p_url = HTTP.parse_uri( url )
			return nil, url if p_url.host == nil || p_url.port == nil || p_url.request_uri == nil
			proxy_host, proxy_port, proxy_user, proxy_pass = HTTP.get_url_proxy_settings( url )

			data, full_headers = MultipartFormData.prepare_query( params )
			full_headers["User-Agent"] = @@user_agent
			full_headers["Referer"] = "#{p_url.scheme}://#{p_url.host}"
			full_headers.merge!( headers ) if headers

			http = Net::HTTP.new( p_url.host, p_url.port, proxy_host, proxy_port, proxy_user, proxy_pass )
			response = http.request_post( p_url.request_uri, data, full_headers )

			case response
				when Net::HTTPSuccess
				when Net::HTTPRedirection, Net::HTTPFound
					if follow == 0
						response = nil
					elsif follow > 0
						response, url = HTTP.fetch_page_get( response["location"], nil, follow-1 )
					end
				else
					response = nil
			end

			return response, url

		rescue Errno::ETIMEDOUT, Errno::EBADF, EOFError => e
			raise TimeoutError.new( e.to_s )
		end
	end

end


