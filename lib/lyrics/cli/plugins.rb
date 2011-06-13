# Copyright (C) 2007 by Sergio Pistone
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

require File.expand_path( File.dirname( __FILE__ ) + "/../mediawikilyrics" )
require File.expand_path( File.dirname( __FILE__ ) + "/pluginadapter" )
require File.expand_path( File.dirname( __FILE__ ) + "/wikipluginadapter" )

module Plugins

  @@ALL  = []
  @@WIKI = []

  def Plugins.find_plugins()
    plugins = {}
    Dir.new( File.expand_path( File.dirname( __FILE__ ) + "/.." ) ).each() do |filename|
      filename = File.expand_path( File.dirname( __FILE__ ) + "/../" + filename )
      if File.file?( filename ) && (md = /\/lyrics_([A-Za-z_0-9]*)\.rb$/.match( filename ))
        plugins[md[1]] = filename
      end
    end
    return plugins
  end

  def Plugins.load_plugins( plugins )
    plugins.each() do |classname, filename|
      require( filename ? filename : File.expand_path( File.dirname( __FILE__ ) + "/../lyrics_#{classname}.rb" ) )
      classobj = eval( classname )
      if classobj.ancestors().include?( MediaWikiLyrics )
        eval( "class CLI#{classname} < #{classname}\ninclude WikiPluginAdapter\nend" ) # FIXME: refactor
        plugin = eval( "CLI#{classname}.new()" )
        @@WIKI << plugin
      else
        eval( "class CLI#{classname} < #{classname}\ninclude PluginAdapter\nend" ) # FIXME: refactor
        plugin = eval( "CLI#{classname}.new()" )
      end
      @@ALL << plugin
    end
  end


  def Plugins.all_plugins()
    return @@ALL
  end

  def Plugins.all_names()
    return @@ALL.collect(){ |plugin| plugin.plugin_name() }
  end

  def Plugins.wiki_plugins()
    return @@WIKI
  end

  def Plugins.wiki_names()
    return @@WIKI.collect(){ |plugin| plugin.plugin_name() }
  end

  def Plugins.plugin_by_name( name )
    @@ALL.each() do |plugin|
      return plugin if plugin.plugin_name() == name
    end
    return nil
  end

end
