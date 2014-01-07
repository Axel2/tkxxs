# encoding: Windows-1252 :encoding=Windows-1252: 
begin
  require 'tkxxs'
rescue LoadError
  require( File.dirname( File.dirname(__FILE__)) +'/lib/tkxxs')
end
include TKXXS
$VERBOSE = false

##################################################################
##################################################################
# Example for TKXXS
# 
# Tested on Windows with Ruby 1.9.3-installer.
class MyTinyUI
  
  def initialize(  )
    #< # #  CREATE OUTPUT WINDOW  # # # 
    @outW = OutW.new

    #< # # REDIRECT "puts" to Output Window
    # Hence, you can simply write "puts" instead of "@outW.puts" 
    $stdout = @outW # BUT: Doesn't work with OCRA!!

    @outW.puts "Ruby#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
    
    run
  end # initialize
  
  
  def explain_puts(  )
    @outW.puts "'puts' writes to the Output Window."
    puts "And this is from Kernel.puts (redirected stdout)."
    
    @outW.puts_h2 "@outW.puts_h2 writes formated text to the Output Window"
    
    @outW.puts "Other formatings can be implemented."
    puts
  end # explain_puts

  def explain_window_size(  )
    @outW.puts_h2 "WINDOW SIZE"

    @outW.puts <<-HERE.margin
      # When using this little app the first time, you should resize
      # and position all popup windows to your desire. This will be
      # saved for the next start of this app.
    HERE
    
  end # explain_window_size
  
  def explain_ask_single_line(  )
    @outW.puts_h2 "ask_single_line( question, help, :defaultEntry=>DefaultAnswer )"

    help = "This dialog is named 'ask_single_line'"
    ans = ask_single_line(
      "Want to know more?\nPoint the mouse at the entry field!",
      help,
      :defaultEntry =>"Of course"
    )
    
    puts
    @outW.puts help
    @outW.puts 
    print "The answer from 'ask_single_line' was: "
    @outW.puts ans.inspect
    puts
    @outW.puts "'Cancel' returns nil."
    puts
    puts
  end # explain_ask_single_line
  
  def explain_single_choice(  )
    @outW.puts_h2 "single_choice( aryWithChoices, help=nil, hash=nil )"

    help0 = <<-HERE.margin
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
      #   * <tt>:configSection</tt> - (any String, Integer or Float or nil) Not
      #     important. Sets the section in the config-file, where for example the
      #     window size and position is stored.
      #   * <tt>:title</tt> - (String) Title of the dialog window
      #   * <tt>:bd</tt> - (Number as String) ?
      #   * <tt>:searchFieldHelp</tt> - (String) Ballon help of the search field,
      #   * <tt>:returnChoiceAndClient</tt> - returns the right side (+false+) or both sides (+true+) of +aryWithChoices+.
      # 
      # *Returns:* 
      # * The right side of +aryWithChoices+ if :returnChoiceAndClient == +false+ (default),
      # * both sides of +aryWithChoices+ if :returnChoiceAndClient == +true+,
      # * +nil+, if 'Cancel' was clicked.
    HERE
    
    
    help = ['#1: ' + help0, '#2: ' + help0, '#3: ' + help0]

    ans = single_choice(
      [
        [ "You want 1?", 1],
        [ "You want 2?", 2],
        [ "You want 3?", 3],
      ],
      help
    )

    @outW.puts "single_choice returned: #{ ans.inspect }"
    puts
    @outW.puts help0
  end # explain_single_choice

  def explain_multi_choice(  )
    @outW.puts_h2 "multi_choice(aryWithChoices, help=nil, hash=nil)"

    help0 = <<-HERE.margin
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
  #   * <tt>:question</tt> - Like above.
  #   * <tt>:help</tt> - Like above. 
  #   * <tt>:configSection</tt> - (any String, Integer or Float or nil) Not
  #     important. Sets the section in the config-file, where for example the
  #     window size and position is stored.
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
    HERE

    help = [help0, help0, help0]

    ans = multi_choice(
      [
        [ "You want 1?", 1],
        [ "You want 2?", 2],
        [ "You want 3?", 3],
      ],
      help
    )

    @outW.puts "multi_choice returned: #{ ans.inspect }"
    puts
    @outW.puts help0
  end # explain_multi_choice

  def explain_choose_dir(  )
    @outW.puts_h2 "choose_dir( initialdir=nil,help=nil,hash=nil)"

    help = <<-HERE.margin
      # choose_dir( initialdir=nil,help=nil,hash=nil )
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
      #   * <tt>:mode</tt> - Don't modify this!
      #   * <tt>:question</tt> - (String) Your question; +nil+ -> no question.
      #   * <tt>:title</tt> - (String) Title of the dialog window.
      #   * <tt>:defaultEntry</tt> - (String) Path, shown in the entry field. 
      #   * <tt>:validate</tt> - +true+ or +false+; if true, a valid path
      #     must be chosen, canceling the dialog is not possible.
      #   * <tt>:configSection</tt> - (any String, Integer or Float or nil) Not
      #     important. Sets the section in the config-file, where for example the
      #     window size and position is stored.
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
      # TODO: How to choose multiple dirs or even dirs & files?
    HERE


    ans = choose_dir( 
      'c:\WinDows', 
      help, 
      :validate=>true, 
      :defaultEntry=>'c:/windows/system' 
    )

    @outW.puts "choose_dir returned: #{ ans.inspect }"
    puts
    @outW.puts help
  end # explain_choose_dir
  
  def explain_open_files(  )
    @outW.puts_h2 "open_files(initialdir=nil,help=nil,hash=nil)"

    help = <<-HERE.margin
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
      #   * <tt>:configSection</tt> - (any String, Integer or Float or nil) Not
      #     important. Sets the section in the config-file, where for example the
      #     window size and position is stored.
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
      # TODO: When using "Recent"-Button > "Files" or "Favorite"-Button >
      # "Files" you can choose only one from Recent and none from, for
      # example "Browse"; should be multiple.
    HERE

    filetypes = [
        ['Text Files', ['.txt']],
        ['All Files', '*']
      ]

    ans = open_files('c:\Windows', help, :filetypes=>filetypes)

    @outW.puts "open_files returned: #{ ans.inspect }"
    puts
    @outW.puts help
  end # explain_open_files
  
  def explain_open_file(  )
    @outW.puts_h2 "open_file(initialdir=nil,help=nil,hash=nil)"

    help = <<-HERE.margin
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
      #   * <tt>:configSection</tt> - (any String, Integer or Float or nil) Not
      #     important. Sets the section in the config-file, where for example the
      #     window size and position is stored.
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
      # TODO: Does initialdir work?
    HERE

    filetypes = [
        ['Text Files', ['.txt']],
        ['All Files', '*']
      ]

    ans = open_file('c:\WinDows', help, :filetypes=>filetypes)

    @outW.puts "open_file returned: #{ ans.inspect }"
    puts
    @outW.puts help
  end # explain_open_file
  
  def explain_save_file(  )
    @outW.puts_h2 "save_file(initialdir=nil,help=nil,hash=nil)"

    help = <<-HERE.margin
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
      #   * <tt>:configSection</tt> - (any String, Integer or Float or nil) Not
      #     important. Sets the section in the config-file, where for example the
      #     window size and position is stored.
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
      # TODO: Does initialdir work?
    HERE

    filetypes = [
        ['Text Files', ['.txt']],
        ['All Files', '*']
      ]

    ans = save_file('c:\Windows', help, :initialfile=>'my_name', :filetypes=>filetypes)

    @outW.puts "save_file returned: #{ ans.inspect }"
    puts
    @outW.puts help
  end # explain_save_file

  
  def finish(  )
    @outW.puts( "\n\nFINISHED - Close by clicking the close-button ('X') on top of this window.")
  end # finish
  

  
  def run(  )
    explain_puts
    explain_window_size
    explain_ask_single_line
    explain_single_choice
    explain_multi_choice
    explain_choose_dir
    explain_open_files
    explain_open_file
    explain_save_file   
    finish          


    Tk.mainloop  # !!! IMPORTANT !!!
  end # run

end # class MyTinyUI

##########################################################################
##########################################################################
class String
  
  unless String.method_defined?(:margin)
    #################################
    # Provides a margin controlled string. 
    # 
    # From:  
    #   http://facets.rubyforge.org/
    # Example:
    #   x = %Q{
    #         aThis
    #         a     is
    #         a       margin controlled!
    #         }.margin
    # Result:
    #   This
    #        is
    #          margin controlled!
    #
    # Attributes:
    #   n: left margin
    #
    def margin(n=0)
      d = /\A.*\n\s*(.)/.match( self )[1]
      d = /\A\s*(.)/.match( self)[1] unless d
      return '' unless d
      if n == 0
        gsub(/\n\s*\Z/,'').gsub(/^\s*[#{d}]/, '')
      else
        gsub(/\n\s*\Z/,'').gsub(/^\s*[#{d}]/, ' ' * n)
      end
    end
  end # unless

end # class String



##########################################################################
##########################################################################
if $0 == __FILE__
  MyTinyUI.new
end
