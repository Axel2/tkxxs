= TKXXS

* https://github.com/Axel2

== References

* Reference for input dialogs: TKXXS
* Reference for the output window: TKXXS::OutW

TKXXS_CLASSES is intended for developers only.


== Description

TKXXS provides a very simple and very easy to use GUI (graphical user interface) for Ruby; It gives you a persistent output window and popping up (modal) dialogs for input; For a screenshot, see: images/screenshot.png; Tested on Windows, only.

TKXXS shall:

* improve the usability of little applications, which otherwise would use a command line interface (CLI); for example by a GUI-file chooser
* give a simple GUI front-end for apps, which take parameters on the command line. (stdout can easily be redirected to the OutputWindow.)
* take only little more effort and coding time over programming a CLI;
* be able to easily upgrade existing CLI-applications;
* be comfortable in use (e.g. provide incremental search, tool-tip-help, ...);
* be easy to install.


Drawbacks:
* I'v tested it only on Windows. Other operating system probably will need modifications, which I would like to merge in.
* For sure some more drawbacks which I'm not aware of now.


TKXXS uses TK (easy to install).


== Dialogs

As of now, the following dialogs exist:

* ask_single_line
* single_choice
* multi_choice
* open_file
* open_files
* choose_dir
* save_file      

All dialog-methods have three arguments:

* Arg #1: (mostly optional) "The most important thing for this dialog" 
  * ask_single_line -> question
  * single_choice -> choices (not optional)
  * multi_choice -> choices (not optional)
  * open_file -> initialdir
  * open_files -> initialdir
  * choose_dir -> initialdir
  * save_file -> filename      
* Arg #2: (optional) Help string, which is shown in the balloon help
* Arg #3: (optional) Hash, which takes additional arguments and optionally Arg#1 and Arg#2.

== Small Example (see: samples/small_example.rb)

  require 'tkxxs'
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


When running this script, you should resize the popping up windows as you like; size and position will be stored for the next time.

You close the application simply by clicking the close-icon on top of the output window.

== More elaborated example

See samples/big_example.rb


== Installation

=== Prerequisites

* Tested only on Windows
* Ruby 1.8.7 or 1.9.x with TK (e.g. RubyInstaller)
* gem Platform (starting with capital letter "P"!)

=== Install

  gem install tkxxs

== Misc

TKXXS stands for "TK very very small".

== TODO

* TODO: Encodings OK?
* TODO: Write instruction for using OCRA with TKXXS.
* TODO: There are several not-so-good things; I marked them with "TODO" in the doc and in the source code.
* TODO: Find somebody to improve the English wording.
* TODO: Prepare for localization (at least, translation). May be these are a starting points: 
  * discussion[https://www.ruby-forum.com/topic/178478]
  * discussion[https://www.ruby-forum.com/topic/4402551]
  * ruby-gettext[http://www.yotabanana.com/hiki/ruby-gettext.html]
  * r18n[https://github.com/ai/r18n]
  * i18n[http://guides.rubyonrails.org/i18n.html]

== Future

2013-12-29: I wrote this code several years ago. Now I thought I should document it and give it to public. I'll _not_ develop it further, but I'll try to include pull requests.

== For developers

* For user's doc, tkxxs_classes.rb is not rdoc'ed in order to get a clearer documentation.
* To create documentation of all files: 
  <tt>rdoc -t TKXXS --force-update [-f hanna] -x ./samples --main ./tkxxs/README.rdoc ./tkxxs/README.rdoc ./lib</tt>
* Class names inside module TKXXS_CLASSES end with capital letter D.
* Arguments of "initialize" in tkxxs_classes.rb are documented at the corresponding module methods of TKXXS, if they exist (to avoid duplicates of documentation).


== LICENSE:

(The MIT License)

Copyright (c) 2010-2014 Axel Friedrich and contributors (see the CONTRIBUTORS file)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.










