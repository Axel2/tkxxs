# encoding: windows-1252 
# Copyright (c) 2010-2014 Axel Friedrich
$stdout.sync = true
$stderr.sync = true
$FILE_SEP = File::ALT_SEPARATOR || File::SEPARATOR
$__DIR__ = File.dirname( File.expand_path( __FILE__ ) ).gsub('\\', '/')
$__DIR0__ = File.dirname( File.expand_path( $0 ) ).gsub('\\', '/')
$: << File.dirname( File.expand_path( __FILE__ ) ) 
$:.uniq!

require 'fileutils'
require 'yaml'
require 'platform'

class Object 
  ##################################################################
  # ,dup,nil,Fixnum,can't dup Fixnum
  # 
  # Potential solution for  x = x.dup if x;  x = x.is_a?(Fixnum)  ?  x  :  x.dup
  #
  # From: comp.lang.ruby, Feb 17 2007, "Oppinions on RCR for dup on immutable classes"
  def dup? 
    dup # Better?: true
  rescue TypeError 
    false 
  end 
end # class Object

##########################################################################
##########################################################################
# Keywords: ,configuration ,ini ,preferences ,setup
# Helps storing and managing configuration data. At present, uses YAML-files to
# store the data.
# 
# Important methods:
# 
#   Conf.new
#   Conf#filename   Returns the full path of file, where Conf is saved 
#   Conf#section= section   section must be String, Integer, Float or nil, _not_ a Symbol
#   Conf#or_default(key, defaultValue)  
#   Conf#[key]= value   key must be a Symbol or String
#   Conf#[key]   Returns the stored value
#   Conf#save   Writes Conf to file
#   Conf#instant_save = true/false: switches on save to file for every change of Conf
# 
# Having keys and section of the same type and value is no problem.
# 
# Example usage:
# 
#   require 'axel/conf'
#   CONF = Conf.new  # Filename for storing CONF can be given as attribute;
#   
#   class MyClass
#     
#     def initialize(  )
#       CONF.section = "my_section_1" # Optional, default is provided
#       # Defines a section (hash key) where to read and store data
#       p x = CONF.or_default( :x, 123 ) 
#       # If run the first time, usually Conf["my_section"][:x] is not set to any value.
#       # If Conf["my_section"][:x] is not set to any value, sets x to 123,
#       # stores 123 in Conf["my_section"][:x] and saves it to the conf-File.
#       # If run the next time, Conf["my_section"][:x] is already set to a value
#       # and x is set to the value of Conf["my_section"][:x]
#   
#       p @y = CONF.or_default( :@y, "abc" )
#   
#       puts "Config-File is: " + CONF.filename
#       myMethod(x)
#     end # initialize
#   
#     def myMethod( x )
#       x = x*x
#       @y = "new_y"
#   
#       CONF[:x] = x  # sets Conf["my_section"][:x] to the new value of x
#       CONF[:@y] = @y
#       puts "CONF[:x] is " + CONF[:x].inspect
#       puts "CONF[:@y] is " + CONF[:@y].inspect
#   
#       CONF.save # saves the content of Conf.
#     end # myMethod
#     
#   end # MyClass
#   
#   klass = MyClass.new
# 
class Conf < Hash

  alias of []
  alias orig_to_hash to_hash

  attr_accessor :instant_save
  attr_reader :section
  ##########################################################################
  # Attributes: configFileDNE: path including filename and fileextension
  def initialize( configFileDNE=Conf.filename_proposal )
#p :xxx
    raise unless configFileDNE
    @configFileDNE = configFileDNE.dup.strip.gsub('\\', '/')
    @instant_save = false
    @section = nil
    
    if File.file?( @configFileDNE )
      dataFromFile = read
      self.replace( dataFromFile )  if dataFromFile
    end
#exit
    self.section = nil  unless self.has_key?(nil) # section "nil" always needed

    super()
    save()  # writeable?
  end # initialize
  
  def delete_conf_file(  )
    File.delete( @configFileDNE )
  end # delete_conf_file
  
  def to_hash(  )
    h = Hash.new
    self.each {|key, val|  
      h[key] =  val.dup  ?  val.dup  : val
    }
    h
  end # to_hash
  
  ##################################################################
  # Returns the filename of the config file
  def filename(  )
    @configFileDNE
  end # filename
  
  ##################################################################
  # Returns the value corresponding to key, while Config is pointing to the
  # section set by Conf::section= . Attributes: key: Symbol or String
  def []( key )
    raise "Key must be a Symbol or String" unless key.is_a?( Symbol )  ||  key.is_a?( String )

    res = self.of(@section)[key]
    res = res.dup?  ?  res.dup  :  res
    res
  end # []
  
  ##################################################################
  # Sets the value for a corresponding key. If key does not exist, it will be created.
  # Attributes: key: Symbol or String; value
  def []=( key, value )
    raise "key must be a Symbol or String" unless key.is_a?( Symbol )  ||  key.is_a?( String )

    self.of(@section).store( key, value)
    self.save  if @instant_save
    value
  end # []=

  ##################################################################
  # If key is not an existing key, key will be created with value = 
  # defaultValue and saves it to the config-File. Returns defaultValue.
  # 
  # If key is an exsiting key, the correspondig value will be returned.
  def or_default( key, defaultValue )
    raise "key must be a Symbol or String" unless key.is_a?( Symbol )  ||  key.is_a?( String )

    if self.of(@section).has_key?( key ) # ToDo: Nicer: create Conf::has_key?
      res = self[key]
    else
      self[key]= defaultValue
      res = defaultValue
      self.save  ## if @instant_save # 2009-06-11
    end

    res
  end # default[]=
  
  ##################################################################
  # Sets Config to a section. Different sections may have the same keys.
  # section=nil is a valid section (it's somehow the 'root'-section)
  # Attributes: section = any String, Integer or Float or nil; default is nil
  def section=( section=nil )
    unless ( section.is_a?(String) || section.is_a?(Integer) || section.is_a?(Float) || !section )
      raise "Section must be String, Integer, Float or nil but #{ section.inspect } is a #{ section.class }!"
    end
    unless self.has_key?(section)
      self.store(section, {})
      self.save  if @instant_save
    end
    
    @section = section.dup?  ?  section.dup  :  nil
  end # section= 

  def read()
    FileUtils.mkpath( File.dirname( @configFileDNE ) )
    # Ruby 1.8.7 cannot read psych-formated YAML-Files. As of 2013-03-15, Ruby
    # 1.8.7 and 1.9 can read syck-formated YAML Files. For compatibility, I
    # choose syck-format.
    YAML::ENGINE.yamler = "syck"  if YAML.const_defined?( :ENGINE )
    File.open( @configFileDNE ) { |f|   YAML.load(f)  }
  end

  ## def save()
  ##   FileUtils.mkpath( File.dirname( @configFileDNE ) )
  ##   File.open( @configFileDNE, "w" ) { |f|    YAML.dump(self, f)   }
  ## end
  
  def save()
    FileUtils.mkpath( File.dirname( @configFileDNE ) )
    YAML::ENGINE.yamler = "syck"   if YAML.const_defined?( :ENGINE )
    File.open( @configFileDNE, "w" ) { |f|    YAML.dump(self, f)   }
    # I write a 2nd File in psych-format in case syck is not longer available
    # sometimes.
    if YAML.const_defined?( :ENGINE )
      YAML::ENGINE.yamler = "psych"
      File.open( @configFileDNE + '_psy', "w" ) { |f|    YAML.dump(self, f)   }
    end
  end


  ##################################################################
  # Deletes the config-File and clears all data of Conf.
  def delete(  )
    File.delete(@configFileDNE)
    self.clear
    self
  end # delete
  
  ##################################################################
  # From: Joel VanderWerf: "preferences-0.3.0".
  # Utility method for guessing a suitable directory to store preferences.
  # On win32, tries +APPDATA+, +USERPROFILE+, and +HOME+. On other platforms,
  # tries +HOME+ and ~. Raises EnvError if preferences dir cannot be chosen.
  # Not called by any of the Preferences library code, but available to the
  # client code for constructing an argument to Preferences.new.
  # 
  # Some modifications by Axel
  def Conf.dir
      case Platform::OS.to_s.downcase
      when 'win32'
        dir = 
          ENV['APPDATA'] ||  # C:\Documents and Settings\name\Application Data
          ENV['USERPROFILE'] || # C:\Documents and Settings\name
          ENV['HOME']
      else
        dir =
          ENV['HOME'] ||
          File.expand_path('~')
      end

      unless dir
        raise EnvError, "Can't determine a configuration directory."
      end
    dir = dir.gsub('\\', '/')
    dir
  end #  Conf.dir
  
  def Conf.filename_proposal( extension='.cfg' )
    fileN = File.basename( $0, File.extname($0) )
    configFileDNE = File.join( Conf.dir, fileN, fileN + extension.to_s)
    configFileDNE
  end # Conf.filename_proposal

end # class Conf
