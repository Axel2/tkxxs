begin
  require 'tkxxs'
rescue LoadError
  require( File.dirname( File.dirname(__FILE__)) +'/lib/tkxxs')
end
include TKXXS

class MyTinyUI
  
  def initialize(  )
    @outW = OutW.new  # create Output Window
    @outW.puts "Hello"
    ask_name
    
    Tk.mainloop  # You always needs this!
  end # initialize

  def ask_name(  )
    name = ask_single_line("Your name?")
    @outW.puts "Hello #{name}."
  end # ask_name
end

MyTinyUI.new