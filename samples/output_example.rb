begin
  require 'tkxxs'
rescue LoadError
  require( File.dirname( File.dirname(__FILE__)) +'/lib/tkxxs')
end
include TKXXS

class MyTinyUI

  def initialize(  )
    @outW = OutW.new  # create Output Window
    @outW.puts_h2 "Output methods demonstration: puts, puts_h2, p, printf and write"
    @outW.puts "This is a call to OutW#puts with", "two strings and an array", [1, 2, 3]
    @outW.puts_h2 "This is a call to OutW#puts_h2 with", "two strings and an array", [1, 2, 3]
    @outW.p "This is a call to OutW#p with a string. And next line will be an array"
    @outW.p [1, 2, 3]
    @outW.printf "%s => %010.3f\n", "This is a call to OutW#printf with Math::PI and \"%s %010.3f\" as formatting string", Math::PI
    @outW.write "This is a call to OutW#write, with one string"

    Tk.mainloop  # You always needs this!
  end # initialize
end

MyTinyUI.new