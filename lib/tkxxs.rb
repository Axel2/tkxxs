# encoding: Windows-1252 :encoding=Windows-1252: 
# Copyright (c) 2010-2014 Axel Friedrich

$stdout.sync = true
$stderr.sync = true
STDOUT.sync = true
STDERR.sync = true
DIR_OF_TKXXS = File.dirname( File.expand_path( __FILE__ ) ).gsub('\\', '/')
$: << DIR_OF_TKXXS
$:.uniq!
$FILE_SEP = File::ALT_SEPARATOR || File::SEPARATOR 

require 'tkxxs/conf'
require 'tk'
require 'tkextlib/tile'
require( File.dirname(DIR_OF_TKXXS) + '/ext/tkballoonhelp.rb' )
require 'stringio'
##/ ##require 'tkrbwidget/tkballoonhelp/tkballoonhelp.rb'
##/ ##require 'ext/tkballoonhelp/tkballoonhelp.rb'
##/ if $0 == __FILE__
##/   ##/ require 'ext/conf/conf'
##/   require 'axel/conf'
CONF = Conf.new unless defined?(CONF)
STDOUT.puts "CONFIG-FILENAME is: #{ CONF.filename.gsub('/',$FILE_SEP) }" 
##/ end
require 'platform'  unless defined?(Platform::OS)
require 'tkxxs/version'
require 'tkxxs/tkxxs_classes'
##require 'pry'

##########################################################################
##########################################################################
module TKXXS
  include Tk::RbWidget
  include Tk::Tile
  $tkxxs_ = Hash.new unless defined?( $tkxxs_ )
  CONF[:recentDirsSize] = CONF[:recentDirsSize] || 100
  CONF[:recentFilesSize] = CONF[:recentFilesSize] || 100

  ##########################################################################
  ##########################################################################
  # 
  class Tk::RbWidget::BalloonHelp # :nodoc: 
    
      alias :orig_initialize :initialize

      ##################################################################
      # Setting defaults
      def initialize( parent=nil, keys={} )
        keys = {
          :interval=>300, # ms
          :background=>'LightYellow',
          :relief=>:ridge, :justify=>:left,
        }.merge(keys)
        orig_initialize(parent, keys)
      end # initialize
        
  end # class Tk::RbWidget::BalloonHelp

  ##########################################################################
  ##########################################################################
  # You create an Output Window like this:
  #   @outW = OutW.new
  # You can write to the Output Window like this:
  #   @outW.puts "Hallo"
  # OR, you can redirect stdout to @outW:
  #   $stdout = @outW
  # Then you can simply write:
  #   puts "Hallo" 
  # to write to the Output Window.
  # This means, if you have an existing application which uses +puts+
  # to write to the console, you can easily make it to write to the
  # Output Window!
  # BUT: Unfortunately, this is not compatible with OCRA and pry (as
  # of 2013-12). When you want to use OCRA or pry, you cannot use this
  # redirection of stdout.
  class OutW < TKXXS_CLASSES::TextW
    CONF = nil  unless defined?(CONF)
    
    def initialize( hash={} )
      @alive = true
      teardownDone = false
      at_exit { self.destroy  }

      #----  Root
      img = TkPhotoImage.new(:file=>"#{ DIR_OF_TKXXS }/icon.gif")
      @root = TkRoot.new(:iconphoto_default=>img )

      userscreen(@root)  unless $tkxxs_[:userscreenx]
      if CONF
        @root.geometry = 
          CONF.or_default( :outWGeom, '400x300+100+0' ) 
      end
      #----  Root-bindings
      @root.bind('Destroy') {
        unless teardownDone
          notify_dying
          if CONF
            CONF[:outWGeom] = @root.geometry
            STDOUT.puts "Saving config to #{ CONF.filename.gsub('/', $FILE_SEP) }"
            CONF.save
          end
          teardownDone = true
        end # unless
      }
      
      #----  TopFrame
      top = Frame.new.pack(:expand=>true, :fill=>:both)
      
      #----  outWindow
      ##/ @outW = TextW.new(top)
      super(top, hash) 
      @tagH2 = TkTextTag.new(self, :font=>"Courier 14 bold")
      @tagSel = TkTextTagSel.new(self)
      bind('Control-Key-a') {
        # From:
        # "Using Control-a to select all text in a text widget : TCL",
        # http://objectmix.com/tcl/35276-using-control-select-all-text-text-widget.html
        @tagSel.add('0.0', :end)
        Kernel.raise TkCallbackBreak
      }
      @tkxxs_buffer = StringIO.new

    end # initialize
    
    ##################################################################
    # Like Kernel::puts. Write a String to the Output Window.
    def puts( *args )
      @tkxxs_buffer.reopen
      @tkxxs_buffer.puts args
      self.insert(:end, @tkxxs_buffer.string)
      self.see :end
      ##/ self.update # Nötig?
    end # puts

    ##################################################################
    # puts, formated as heading level 2 
    def puts_h2( *args )
      @tkxxs_buffer.reopen
      @tkxxs_buffer.puts args
      self.insert(:end, @tkxxs_buffer.string, @tagH2)
    end # puts_h2
    
    ##################################################################
    # Like Kernel::print. Print a String to the Output Window.
    def print( *args )
      @tkxxs_buffer.reopen
      @tkxxs_buffer.print args
      self.insert('end', @tkxxs_buffer)
      self.see :end
      ##/ self.update # Nötig?
    end # print
    
    # TODO def p()

    # :nodoc:
    def write( str )
      ##self.insert(:end, "\n" + str)
      @tkxxs_buffer.reopen
      @tkxxs_buffer.write str
      self.insert(:end, @tkxxs_buffer.string)
      self.see :end
      ##/ self.update # Nötig?
    end # write

    ##########################################################################
    # :nodoc:
    # Does nothing, just for compatibility
    def sync=( x )
      # nothing to do
    end # sync=
  
    # :nodoc:
    def flush
      self.update
    end # 
    
    # :nodoc:
    def tty?(  )
      false
    end # tty?
    

    # :nodoc:
    def private____________________________(  )
    end # private____________________________
    
    ##################################################################
    # "private"
    def userscreen( root )
      if Platform::OS == :win32
        root.state('zoomed') # OK on Windows
        ##/ root.wm_state('zoomed') # OK on Windows
        ##/ root.wm_zoomed # method missing
        ##/ root.wm_attributes('zoomed')
        ##/ root.wm_maximized # method missing
      else
        # Linux: works
        # Other: not tested
        root.height = root.winfo_screenheight
        root.width = root.winfo_screenwidth
      end
      root.update

      root.winfo_geometry  =~ /(\d+)x(\d+)\+([+-]?\d+)\+([+-]?\d+)/
      xwg = $3.to_i 
      ywg = $4.to_i
      root.geometry =~ /(\d+)x(\d+)\+([+-]?\d+)\+([+-]?\d+)/ 
      gw = $1.to_i 
      gh = $2.to_i 
      
      ## sw = root.winfo_screenwidth 
      ## sh = root.winfo_screenheight 
      
      rx = root.winfo_rootx 
      ry = root.winfo_rooty  # maybe, taskbar height 
      
      border = -[xwg,ywg].min
      userscreenx = xwg + border
      userscreeny= ywg + border
      userscreenwidth = gw
      userscreenheight = gh + ry - ywg - border

      $tkxxs_[:userscreenx     ] =  userscreenx
      $tkxxs_[:userscreeny     ] =  userscreeny
      $tkxxs_[:userscreenwidth ] =  userscreenwidth
      $tkxxs_[:userscreenheight] =  userscreenheight

      root.state('normal')
      nil
    end # userscreen

    ##################################################################
    # "private"
    def notify_dying(  )
      @alive = false
    end # notify_dying

    ##################################################################
    # "private"
    def alive?(  )
      @alive
    end # alive?
  end # class OutW

  ##################################################################
  ##################################################################
  # Depreciated (replaced by OutW).
  class LogW < OutW # :nodoc:
  end

  ##########################################################################
  ##########################################################################
  def messageBoxExamples
    # TODO: Is this usefull?
    ##################################################################
    # :type: :abortretryignore, :ok, :okcancel, :retrycancel, :yesno, :yesnocancel
    # :icon: :error, :info, :question or :warning (default: info)
    # :detail: Specifies an auxiliary message to the main message given by
    #   the -message option. Where supported by the underlying OS, the
    #   message detail will be presented in a less emphasized font than the
    #   main message.
    # Returns: A String describing the pressed button ("ok", "cancel", "retry", "ignore", ...)
    # Balloonhelp funktioniert damit nicht (oder?).
    # 
    ans = Tk.messageBox( :type=>:yesno,:icon=>:question,
      :title=>"Next",
      :message=>"xxx",
      :detail=>"xxx"
    )
    #    
    #    puts sprintf("--DEBUG: button: %1s ", button.inspect)   #loe
  end # class MessageBoxExamples

  ##########################################################################
  # ask_single_line(question=nil, help=nil, hash=nil)
  #
  # Ask for a single line of text. 
  # 
  # *Params*:
  # * +question+ - (String, optional) Your question;  +nil+ => Default question 
  # * +help+ - (String, optional) Text used in the BalloonHelp;  +nil+ => No help text 
  # * +hash+ - (Hash, optional) 
  #   * <tt>:question</tt> - Like above.
  #   * <tt>:help</tt> - Like above. 
  #   * <tt>:configSection</tt> - (any String, Integer, Float or nil)
  #     Sets the section where to store and read from config settings.
  #     Default = nil. If key is not given, section remains unchanged.
  #   * <tt>:defaultEntry</tt> - (String) Default answer. 
  # 
  # *Returns*: (String or nil) The answer of the dialog. 'Cancel' returns nil.
  # 
  # *Example:* 
  #    help = "This dialog is named 'ask_single_line'"
  #    ans = ask_single_line(
  #      "Want to know more?\nPoint with the mouse to the entry field!",
  #      help,
  #      :defaultEntry =>"Of course"
  #    )     
  def ask_single_line( *args )
    TKXXS_CLASSES::AskSingleLineD.new(*args).answer
  end # ask_single_line

  ##################################################################
  # single_choice( aryWithChoices, help=nil, hash=nil )
  # 
  # *Params*:
  # * +aryWithChoices+ - (Array) one of the following formats:
  #   * [ choiceStrA, choiceStrB, ...]
  #   * [ [choiceStrA,objectA], [choiceStrB,objectB], ...  ]
  #   * [ [choiceStrA,objectA,helpStrA], [choiceStrB,objectB,helpStrB], ...]
  #   Quite usefull: a Proc for object.
  # * +help+ - (String, optional) Array, with one help-String for each choice element!;  +nil+ => No help text 
  # * +hash+ - (Hash, optional) 
  #   * <tt>:question</tt> - Like above.
  #   * <tt>:help</tt> - Like above. 
  #   * <tt>:configSection</tt> - (any String, Integer, Float or nil)
  #     Sets the section where to store and read from config settings.
  #     Default = nil. If key is not given, section remains unchanged.
  #   * <tt>:title</tt> - (String) Title of the dialog window
  #   * <tt>:bd</tt> - (Number as String) ?
  #   * <tt>:searchFieldHelp</tt> - (String) Ballon help of the search field,
  #   * <tt>:returnChoiceAndClient</tt> - returns the right side (+false+) or both sides (+true+) of +aryWithChoices+.
  # 
  # *Returns:* 
  # * The chosen right sides of +aryWithChoices+ if :returnChoiceAndClient == +false+ (default),
  # * An Array of the chosen right and left side of +aryWithChoices+ if :returnChoiceAndClient == +true+,
  # * +nil+, if 'Cancel' was clicked.
  # 
  # *Example:*   
  #    help = ['Help #1', 'Help #2', 'Help #3']
  #    ans = single_choice(
  #      [
  #        [ "You want 1?", 1],
  #        [ "You want 2?", 2],
  #        [ "You want 3?", 3],
  #      ],
  #      help
  #    )
  #
  # *TODO:*  Choice-search field: ä (&auml;) does not work?
  def single_choice( *args )
    TKXXS_CLASSES::SingleChoiceD.new(*args).answer
  end # single_choice
  
  ##################################################################
  # multi_choice( aryWithChoices, help=nil, hash=nil )
  # 
  # *Params*:
  # * +aryWithChoices+ - (Array) one of the following formats:
  #   * [ choiceStrA, choiceStrB, ...]
  #   * [ [choiceStrA,objectA], [choiceStrB,objectB], ...  ]
  #   * [ [choiceStrA,objectA,helpStrA], [choiceStrB,objectB,helpStrB], ...]
  #   Quite usefull: a Proc for object.
  # * +help+ - (String, optional) Array, with one help-String for each choice element!;  +nil+ => No help text 
  # * +hash+ - (Hash, optional) 
  #   * <tt>:question</tt> - (String) Your question; +nil+ -> no question.
  #   * <tt>:help</tt> - Like above. 
  #   * <tt>:configSection</tt> - (any String, Integer, Float or nil)
  #     Sets the section where to store and read from config settings.
  #     Default = nil. If key is not given, section remains unchanged.
  #   * <tt>:title</tt> - (String) Title of the dialog window
  #   * <tt>:bd</tt> - (Number as String) ?
  #   * <tt>:selectmode => :multiple</tt> - Obsolet?
  #   * <tt>:searchFieldHelp</tt> - (String) Ballon help of the search field, searchField not implemented yet
  #   * <tt>:returnChoiceAndClient</tt> - returns the right side (+false+) or both sides (+true+) of +aryWithChoices+.
  # 
  # *Returns:* 
  # * An Array of the chosen right sides of +aryWithChoices+ if :returnChoiceAndClient == +false+ (default),
  # * An Array of the chosen right and left sides of +aryWithChoices+ if :returnChoiceAndClient == +true+,
  # * +nil+, if 'Cancel' was clicked.
  # 
  # *Example:*   
  #    help = ['Help #1', 'Help #2', 'Help #3']
  #    ans = single_choice(
  #      [
  #        [ "You want 1?", 1],
  #        [ "You want 2?", 2],
  #        [ "You want 3?", 3],
  #      ],
  #      help
  #    )
  def multi_choice( *args )
    TKXXS_CLASSES::MultiChoiceD.new(*args).answer
  end # multi_choice

  ##########################################################################
  # choose_dir( initialdir=nil,help=nil,hash=nil )
  #
  # *Params*:
  # * +initialdir+ - (String, optional) Initial dir; default = +nil+
  #   -> Working dir at the time of calling this method.
  # * +help+ - (String, optional) ; Text used in the BalloonHelp;
  #   default = +nil+ -> No help.
  # * +hash+ - (Hash, optional) 
  #   * <tt>:initialdir</tt> - Like above. 
  #   * <tt>:help</tt> - Like above. 
  #   * <tt>:mode</tt> - Don't modify this!
  #   * <tt>:question</tt> - (String) Your question; +nil+ -> no question.
  #   * <tt>:title</tt> - (String) Title of the dialog window.
  #   * <tt>:defaultEntry</tt> - (String) Path, shown in the entry field. 
  #   * <tt>:validate</tt> - +true+ or +false+; if true, a valid path
  #     must be chosen, canceling the dialog is not possible.
  #   * <tt>:configSection</tt> - (any String, Integer, Float or nil)
  #     Sets the section where to store and read from config settings.
  #     Default = nil. If key is not given, section remains unchanged.
  # 
  # *Returns:* (String) Path of the chosen dir;  +nil+, if 'Cancel' was clicked.
  # 
  # *Example:*   
  # 
  #   help = "Pick a dir."
  #   ans = choose_dir( 
  #     'c:\WinDows', 
  #     help, 
  #     :validate=>true, 
  #     :defaultEntry=>'c:/windows/system' 
  #   )
  # 
  # *TODO:* How to choose multiple dirs or even dirs & files?
  def choose_dir( *args ) # initialdir
    TKXXS_CLASSES::ChooseDirD.new(*args).answer
  end # choose_dir

  ##########################################################################
  # open_files( initialdir=nil,help=nil,hash=nil )
  # 
  # To get this dialog explain, run the example and point the mouse
  # at each button.
  #
  # *Params*:
  # * +initialdir+ - (String, optional) Initial dir; default = +nil+
  #   -> Working dir at the time of calling this method.
  # * +help+ - (String, optional) ; Text used in the BalloonHelp;
  #   default = +nil+ -> No help.
  # * +hash+ - (Hash, optional) 
  #   * <tt>:initialdir</tt> - Like above. 
  #   * <tt>:help</tt> - Like above. 
  #   * <tt>:mode</tt> - Don't change this!
  #   * <tt>:multiple</tt> - Don't change this!
  #   * <tt>:question</tt> - (String) Your question; +nil+ -> no question.
  #   * <tt>:title</tt> - (String) Title of the dialog window.
  #   * <tt>:defaultEntry</tt> - (String) Path, shown in the entry field. 
  #   * <tt>:validate</tt> - +true+ or +false+; if true, a valid path
  #     must be chosen, canceling the dialog is not possible.
  #   * <tt>:configSection</tt> - (any String, Integer, Float or nil)
  #     Sets the section where to store and read from config settings.
  #     Default = nil. If key is not given, section remains unchanged.
  #   * <tt>:filetypes</tt> - (Array of Arrays) Filter for the file types
  #     Format of the (inner) Arrays: 
  #     * First element: (String) Name of the file type, e.g. 'Ruby files'
  #     * Second element: (Array) List of extensions for the file type, e.g. ['.rb','.rbw']
  #     * Third element: (String, optional) Mac file type(s), e.g. 'TEXT'
  #     * Example:
  #         filetypes = [
  #           ['Text files',       ['.txt','.doc']          ],
  #           ['Text files',       [],                      'TEXT' ],
  #           ['Ruby Scripts',     ['.rb'],                 'TEXT' ],
  #           ['Tcl Scripts',      ['.tcl'],                'TEXT' ],
  #           ['C Source Files',   ['.c','.h']              ],
  #           ['All Source Files', ['.rb','.tcl','.c','.h'] ],
  #           ['Image Files',      ['.gif']                 ],
  #           ['Image Files',      ['.jpeg','.jpg']         ],
  #           ['Image Files',      [],                      ['GIFF','JPEG']],
  #           ['All files',        '*'                      ]
  #         ]
  # *Returns:* (Array) Paths of the chosen files;  +nil+, if 'Cancel' was clicked.
  # 
  # *Example:*   
  # 
  #    filetypes = [
  #        ['Log Files', ['.log']],
  #        ['All Files', '*']
  #      ]
  #   
  #    ans = open_files('c:\Windows', :filetypes=>filetypes)
  # 
  # *TODO:* When using "Recent"-Button > "Files" or "Favorite"-Button >
  # "Files" you can choose only one from Recent and none from, for
  # example "Browse"; should be multiple.
  def open_files( *args )
    TKXXS_CLASSES::OpenFilesD.new(*args).answer
  end # open_files

  ##################################################################
  # open_file( initialdir=nil,help=nil,hash=nil )
  # 
  # To get this dialog explain, run the example and point the mouse
  # at each button.
  #
  # *Params*:
  # * +initialdir+ - (String, optional) Initial dir; default = +nil+
  #   -> Working dir at the time of calling this method.
  # * +help+ - (String, optional) ; Text used in the BalloonHelp;
  #   default = +nil+ -> No help.
  # * +hash+ - (Hash, optional) 
  #   * <tt>:initialdir</tt> - Like above. 
  #   * <tt>:help</tt> - Like above. 
  #   * <tt>:mode</tt> - Don't change this!
  #   * <tt>:multiple</tt> - Don't change this!
  #   * <tt>:question</tt> - (String) Your question; +nil+ -> no question.
  #   * <tt>:title</tt> - (String) Title of the dialog window.
  #   * <tt>:defaultEntry</tt> - (String) Path, shown in the entry field. 
  #   * <tt>:validate</tt> - +true+ or +false+; if true, a valid path
  #     must be chosen, canceling the dialog is not possible.
  #   * <tt>:configSection</tt> - (any String, Integer, Float or nil)
  #     Sets the section where to store and read from config settings.
  #     Default = nil. If key is not given, section remains unchanged.
  #   * <tt>:filetypes</tt> - (Array of Arrays) Filter for the file types
  #     Format of the (inner) Arrays: 
  #     * First element: (String) Name of the file type, e.g. 'Ruby files'
  #     * Second element: (Array) List of extensions for the file type, e.g. ['.rb','.rbw']
  #     * Third element: (String, optional) Mac file type(s), e.g. 'TEXT'
  #     * Example:
  #         filetypes = [
  #           ['Text files',       ['.txt','.doc']          ],
  #           ['Text files',       [],                      'TEXT' ],
  #           ['Ruby Scripts',     ['.rb'],                 'TEXT' ],
  #           ['Tcl Scripts',      ['.tcl'],                'TEXT' ],
  #           ['C Source Files',   ['.c','.h']              ],
  #           ['All Source Files', ['.rb','.tcl','.c','.h'] ],
  #           ['Image Files',      ['.gif']                 ],
  #           ['Image Files',      ['.jpeg','.jpg']         ],
  #           ['Image Files',      [],                      ['GIFF','JPEG']],
  #           ['All files',        '*'                      ]
  #         ]
  # *Returns:* (Array) Paths of the chosen files;  +nil+, if 'Cancel' was clicked.
  # 
  # *Example:*   
  # 
  #    filetypes = [
  #        ['Log Files', ['.log']],
  #        ['All Files', '*']
  #      ]
  #   
  #    ans = open_file('c:\Windows', :filetypes=>filetypes)
  # 
  # *TODO:* Does initialdir work?
  def open_file( *args )
    TKXXS_CLASSES::OpenFileD.new(*args).answer
  end # open_file

  ##################################################################
  # save_file( initialdir=nil,help=nil,hash=nil )
  # 
  # To get this dialog explain, run the example and point the mouse
  # at each button.
  #
  # *Params*:
  # * +initialdir+ - (String, optional) Initial dir; default = +nil+
  #   -> Working dir at the time of calling this method.
  # * +help+ - (String, optional) ; Text used in the BalloonHelp;
  #   default = +nil+ -> No help.
  # * +hash+ - (Hash, optional) 
  #   * <tt>:initialdir</tt> - Like above. 
  #   * <tt>:help</tt> - Like above. 
  #   * <tt>:initialfile</tt> - (String) Default filename, extension
  #     will be added automatically by filetypes-setting; default =
  #     'Untitled'
  #   * <tt>:mode</tt> - Don't change this!
  #   * <tt>:multiple</tt> - Don't change this!
  #   * <tt>:question</tt> - (String) Your question; +nil+ -> no question.
  #   * <tt>:title</tt> - (String) Title of the dialog window.
  #   * <tt>:defaultEntry</tt> - (String) Path, shown in the entry field. 
  #   * <tt>:validate</tt> - +true+ or +false+; if true, a valid path
  #     must be chosen, canceling the dialog is not possible.
  #   * <tt>:configSection</tt> - (any String, Integer, Float or nil)
  #     Sets the section where to store and read from config settings.
  #     Default = nil. If key is not given, section remains unchanged.
  #   * <tt>:defaultextension</tt> - ??? (Don't change).
  #   * <tt>:filetypes</tt> - (Array of Arrays) Filter for the file types
  #     Format of the (inner) Arrays: 
  #     * First element: (String) Name of the file type, e.g. 'Ruby files'
  #     * Second element: (Array) List of extensions for the file type, e.g. ['.rb','.rbw']
  #     * Third element: (String, optional) Mac file type(s), e.g. 'TEXT'
  #     * Example:
  #         filetypes = [
  #           ['Text files',       ['.txt','.doc']          ],
  #           ['Text files',       [],                      'TEXT' ],
  #           ['Ruby Scripts',     ['.rb'],                 'TEXT' ],
  #           ['Tcl Scripts',      ['.tcl'],                'TEXT' ],
  #           ['C Source Files',   ['.c','.h']              ],
  #           ['All Source Files', ['.rb','.tcl','.c','.h'] ],
  #           ['Image Files',      ['.gif']                 ],
  #           ['Image Files',      ['.jpeg','.jpg']         ],
  #           ['Image Files',      [],                      ['GIFF','JPEG']],
  #           ['All files',        '*'                      ]
  #         ]
  # 
  # *Returns:* (String) Paths of the chosen file;  +nil+, if 'Cancel' was clicked.
  # 
  # *Example:*   
  # 
  #    filetypes = [
  #        ['Log Files', ['.log']],
  #        ['All Files', '*']
  #      ]
  #   
  #    ans = save_file('c:\Windows', :filetypes=>filetypes)
  # 
  # *TODO:* Does initialdir work?
  def save_file( *args )
    TKXXS_CLASSES::SaveFileD.new(*args).answer
  end # save_file
  
  def todo(  ) # :nodoc:
    # * in all balloon-helps, remove interval, background, justify, relief (not needed) 2010-02-19
    # * Build into TK a function for userscreensize, that's for Balloonhelp
    # * 
    # * 
    # * 
    # * 
  end # todo
  
end # module TKXXS

##########################################################################
##########################################################################
if $0 == __FILE__
  $VERBOSE = false
  ##/ require 'axel/conf'
  ##/ CONF = Conf.new
  include TKXXS

  if !true # OutWindow!
    @outW = OutW.new
    $stdout = @outW
  else
    STDOUT.puts "OUTWindow disabled !!!!!!!!!!!!!!!!!!"
  end

  if !true # SingleChoiceD
    choices = File.open(__FILE__.strip + '_dummydata') {|f|  f.read  }
    choices = choices*100
    choices = choices.split("\n")
    help = choices.unshift("abc def abc def abc def abc def abc def abc def abc def abcdef abc def abc def abc def abcdef abc def abc def abc def abcdef abc def abc def abc def abcdef abc def abc def abc def abcdef abc def abc def abc def abc \n"*40)
    ans = SingleChoiceD.new(choices, help).answer
    p(ans)
  end

  if !true # SingleChoiceD
    choices = File.open(__FILE__.strip + '_dummydata') {|f|  f.read  }
    choices = choices*100
    choices = choices.split("\n")
    ans = SingleChoiceD.new(choices, :title=>'Dialogs title').answer
    p(ans)
  end

  if !true # AskSingleLineD
    ans = AskSingleLineD.new("Name?", 'help name').answer
    p(ans)
  end

  if true # MultiChoiceD
    ans = multi_choice(['hund', 'katze'], ['help-hund', 'help-katze'])
    p(ans)
  end

  if !true # AskMultiLineD
    ans = AskMultiLineD.new("Name? "*100, 'my help'*30, :title=>"Dialog's Title").answer
    p(ans)
  end

  if !true # ChooseDirD
    ans = ChooseDirD.new().answer
    p(ans)
  end

  if !true # SaveFileD
    ans = SaveFileD.new().answer
    p(ans)
  end

  if  !true # ChooseDirD
    ans = ChooseDirD.new().answer
    p(ans)
  end

  if !true # OpenFilesD
    ans = OpenFilesD.new(:help=>'Bitte einen Pfad aussuchen').answer
    puts "Returned: #{ ans.inspect }"
  end

  if !true # OpenFileD
    #ans = OpenFileD.new().path
    ans = OpenFileD.new(:validate => true).path
    p(ans)
  end

  if !true # SaveFileD
    ans = SaveFileD.new().answer
    p(ans)
  end

  # p ask_single_line('frage', 'tja....')
  
  #p single_choice([ ['choiceStr1',:choice1, :helpStr1], ['choiceStr2',:choice2, :helpStr2]], :returnChoiceAndClient=>false)

  # p multi_choice([ ['choiceStr1',:choice1, :helpStr1], ['choiceStr2',:choice2, :helpStr2]], :returnChoiceAndClient=>true)

  #p choose_dir( 'C:\_Abfall\Thomas' )

  #p open_files( 'C:\_Abfall\Thomas')

  #p open_file( 'C:\_Abfall\Thomas' )

  ##/ p save_file(  'C:\_Abfall\Thomas'  )

  Tk.mainloop
end

# :mode=ruby: 

