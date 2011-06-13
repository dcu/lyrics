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

require "cgi"

module PluginAdapter

	# Hack to make module methods become class methods when the module gets included
	def PluginAdapter.included( including )
		if including.is_a?( Class )
			including.extend( ClassMethods ) # adds class methods
		else # if including.is_a?( Module )
			including::ClassMethods.append_class_methods( self )
		end
	end

	# Methods under this module will became class methods when the module gets included
	# Note: don't use def self.<method name> but just <method name>
	module ClassMethods
		def ClassMethods.append_class_methods( mod )
			include mod::ClassMethods
		end

		def plugin_name()
			return site_name()
		end

		def notify( message )
			puts plugin_name() + ": " + message.gsub( /\/?<[^>]+>/, "" )
		end
	end

	def plugin_name()
		return self.class.plugin_name()
	end

	def notify( message )
		self.class.notify( message )
	end

end
