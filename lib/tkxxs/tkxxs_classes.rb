# encoding: Windows-1252 :encoding=Windows-1252: 
# Copyright (c) Axel Friedrich 2010-2014
STDOUT.sync = true
STDERR.sync = true

##########################################################################
##########################################################################
class Hash
  
  ##################################################################
  # Somewhat deeper dup
  def dup2!(  )
    self.each_pair {|k,v|
      self[k] = v.dup if v.class == String
    }
    self
  end # dup2!
  
end # class Hash

##########################################################################
##########################################################################
# Creates dialogs for TKXXS
module TKXXS_CLASSES

  ##################################################################
  # Purpose:
  #   Interpret last argument always as +Hash#, independent from the
  #   number of arguments:
  # * Searches for the first argument which is a Hash, from right to
  #   left, starting with the last argument. (TODO: Why not simply
  #   detect if the last argument is a Hash?)
  # * If Hash exists:
  # ** Move the hash to the last element of args.
  # ** Set the element, where the Hash comes from to nil, if it was
  #    not the last element.
  # ** All other elements remain unchanged.
  # * If no Hash exist:
  # ** Sets the last element of args to {} 
  # ** All other elements remain unchanged.
  # 
  # *Returns:* The rearranged args.
  # 
  # Example:
  #   def m1( c=nil,b=nil,a=nil,h=nil )
  #     c, b, a, hash = args_1(c,b,a,h)
  #     p [c, b, a, hash]
  #     
  #     hash = {:a=>'aa',
  #     :b=>'bb',
  #     :c=>'cc'
  #     }.merge(hash)
  #     
  #     c = hash[:c] unless c  
  #     b = hash[:b] unless b  
  #     a = hash[:a] unless a 
  #     nil
  #   end # m1
  # 
  #   m1(:c,:b,:a, {:h=>'hh'}) # => [:c, :b, :a, {:h=>"hh"}] 
  #   m1(:c, {:h=>'hh'})       # => [:c, nil, nil, {:h=>"hh"}] 
  #   m1(:c)                   # => [:c, nil, nil, {}] 
  #   m1()                     # => [nil, nil, nil, {}] 
  # 
  def TKXXS_CLASSES.args_1( *args )
    args = args.reverse
    args.each_with_index {|arg, i|
      if arg.class == Hash
        args[i] = nil
        args[0] = arg
        break
      end
    }
    args[0] =
    unless args[0]
      {}
    else
      ## Marshal.load(Marshal.dump( args[0] ) ) # Doesn't work because of Proc
      args[0].dup2! # args[0] must always be a Hash
    end
    args = args.reverse
    args
  end # TKXXS_CLASSES.args_1

  ##################################################################
  # Set the value of new variables from the values of the hash.
  # 
  # New variables are _always_:  +question+ and +help+. 
  # 
  # 'hash' gets modified.
  # 
  # On the left side of the equal sign:  _always_ 'help, hash,
  # question', thereafter the additional variables. 
  # 
  # Arguments of args_2: 'help,hash,question' and then the (optional)
  # hash-keys, which shall be assigned to the additional variables.
  # :help and :question can be put at arbitrary position, or omitted.
  # hash _must_ have:  :question. 
  # 
  # If the variable +help+ and/or +question+ are already set (not
  # equal +nil+), then they leave unchanged. 
  #
  # EXAMPLE:
  #   help = 'h'
  #   hash = {
  #     :help=>'heeelp', 
  #     :question=>'MyQuestion', 
  #     :title=>'MyTitle', 
  #     :SomethingElse=>'bla'
  #   }
  #   help, hash, question, title = 
  #           TKXXS_CLASSES.args_2( help, hash, question, :title)
  #   # => ["h", {:SomethingElse=>"bla"}, "MyQuestion", "MyTitle"]
  # 
  # * 'h' in +help+ _not_ overwritten, because +help+ was defined before;
  # * Every key in +hash+ deleted, which corresponds to the args of +args_2+;
  # * +question+ now set, because it was _not_ defined before;
  # * +title+ set to <tt>hash[:title]</tt>
  def TKXXS_CLASSES.args_2( help,hash,question,*keys )
    hash.delete(:configSection) if hash[:configSection]
    q = hash.delete(:question)
    question = q unless question
    h = hash.delete(:help)
    help = h unless help
  
    values = [help,hash,question]
    keys.each {|key|
      val = hash.delete(key)
      values << val
    }
    values[1] = hash
    values
  end # TKXXS_CLASSES.args_2

  ##########################################################################
  ##########################################################################
  class TextW < TkText
    include Tk::Tile
    def initialize( parent, hash={} )
      #----  Frame 
      @frame = Frame.new(parent) {padding "3 3 3 3"}.
        pack(:fill=>:both, :expand=>true)

      hash = Marshal.load(Marshal.dump( hash ) ) # Should work because never uses Proc

      hash = {
        :font=>'"Courier New" 10',
        :wrap=>'word',
        :bd=>'2'
      }.merge(hash)
      
      #----  self = TkText
      super(@frame, hash) 
      
      #----  Scrollbars
      sy = Scrollbar.new(@frame)
      sy.pack('side'=>'right', 'fill'=>'y')
      self.yscrollbar(sy)
      
      sx = Scrollbar.new(@frame)
      sx.pack('side'=>'bottom', 'fill'=>'x')
      self.xscrollbar(sx)
      
      self.pack('expand'=>'yes', 'fill'=>'both')
    end # initialize
 
  end # class TextW

  ##########################################################################
  ##########################################################################
  class AskSingleLineD < Tk::Tile::Entry
    include Tk::Tile
    CONF = nil  unless defined?(CONF)
    attr_accessor :dialog # in: "self.dialog
    
    ##########################################################################
    # See: TKXXS.ask_single_line
    def initialize( question=nil, help=nil, hash=nil )
      question, help, hash = TKXXS_CLASSES.args_1(question, help, hash)

      # Must always include:  :question, :help
      hash = { # Default values
        :question => "?",
        :help => nil,
        :defaultEntry => '', 
      }.merge(hash)
  
      # Necessary, because hash[:configSection]  is deleted later on
      # with +args_2+.
      CONF.section = hash[:configSection] if CONF && hash[:configSection]
    
      help, hash, question, defaultEntry = 
        TKXXS_CLASSES.args_2(help,hash,question,:defaultEntry)
      
      teardownDone = false
      @ans = nil
      @goOn = goOn = TkVariable.new 
      # Because you cannot use instance-vars in procs. TODO: smarter way?

      Tk.update # Show any calling widget first to make it lower than @dialog 
      #----  Toplevel: @dialog
      @dialog=Toplevel.new() {title "Please enter your answer..."} 
      @dialog.geometry = CONF[:dialogGeom]  if CONF
      @dialog.raise
      @dialog.bind('Destroy') {
        unless teardownDone
          if CONF
            CONF[:dialogGeom] = @dialog.geometry
          end
          goOn.value = '1' # !
          teardownDone = true
        end
      }

      #----  Frame 
      @frame = Frame.new(@dialog) {padding "3 3 3 3"}.
        pack(:fill=>:both,:expand=>true)

      #----  Label 
      @lbl = Label.new(@frame, :text=>question){
        font $font if $font
        wraplength '5i'
        justify 'left'
      }
      @lbl.grid(:column=>0,:columnspan=>3,:sticky=>'ws')

      #---- self = TkEntry
      super(@frame, hash) 
      self.grid(:column=>0,:columnspan=>3,:sticky=>'ew')
      self.insert(0, defaultEntry)
      bind('Key-Return') {
        ans_( self.get )
        self.dialog.destroy
        goOn.value = '1'
      }

      #----  Button-Cancel 
      @btn = Button.new(@frame, :text=>"Cancel").
        grid(:column=>0,:row=>2)
      @btn.command { 
        self.dialog.destroy 
      }

      #----  Button-OK 
      @btn2 = Button.new(@frame, :text=>"OK").
        grid(:column=>2,:row=>2)
      @btn2.command { 
        ans_( self.get )
        self.dialog.destroy
        goOn.value = '1'
      }

      #----  Balloonhelp
      if help
        BalloonHelp.new(self, :text => help )
      end
      
      @frame.grid_columnconfigure([0,2],:weight=>0)
      @frame.grid_columnconfigure(1,:weight=>1)
      @frame.grid_rowconfigure(0,:weight=>1)
      @frame.grid_rowconfigure([1,2],:weight=>0)

      focus
      update
    end # initialize
    
    ##########################################################################
    # *Returns*: (String or nil) The answer of the dialog. 'Cancel' returns nil.
    def answer(  )
      @dialog.raise
      @goOn.wait
      @ans
    end # ans
    
    private
    
    def private____________________(  )
    end # private____________________
    
    def ans_( ans ) # TODO: Easier way?
      @ans = ans.dup  if ans
    end # ans=
        
  end # class AskSingleLineD


  ##########################################################################
  ##########################################################################
  class AskMultiLineD < TkText
  # class AskMultiLineD < TextW
    include Tk::Tile
    CONF = nil  unless defined?(CONF)
    attr_accessor :dialog # in: "self.dialog

    ##################################################################
    # TODO: implement in TKXXS.
    def initialize( question=nil, help=nil, hash=nil )
      question, help, hash = TKXXS_CLASSES.args_1(question, help, hash)

      # Must always include:  :question, :help
      hash = {
        :question => "?",
        :help => nil,
        :title => "Please enter your answer..."
      }.merge(hash)
  
      # Necessary, because hash[:configSection]  is deleted later on
      # in args_2.
      CONF.section = hash[:configSection] if CONF && hash[:configSection]
    
      # help, hash, question, title = 
      #   TKXXS_CLASSES.args_2( help, hash, question, :title)
      help, hash, question, title = 
        TKXXS_CLASSES.args_2( help, hash, question, :title)
      
      teardownDone = false
      @ans = nil
      @goOn = goOn = TkVariable.new 
      # Because you cannot use instance-vars in procs. TODO: smarter way?

      Tk.update # Show any calling widget first to make it lower than @dialog 
      #----  Toplevel: @dialog
      # @dialog=Toplevel.new() {title('title')} 
      @dialog=Toplevel.new() {title(title)} 
      @dialog.geometry = CONF[:dialogGeom]  if CONF
      @dialog.raise
      @dialog.bind('Destroy') {
        unless teardownDone
          if CONF
            CONF[:dialogGeom] = @dialog.geometry
          end
          goOn.value = '1' # !
          teardownDone = true
        end
      }

      #----  Frame 
      @frame = Frame.new(@dialog) {padding "3 3 3 3"}.
        pack(:fill=>:both,:expand=>true)

      #----  Label 
      @lbl = Label.new(@frame, :text=>question){
        font $font if $font
        wraplength '5i'
        justify 'left'
      }
      @lbl.grid(:sticky=>'news')

      #---- self = TextW
      super(@frame, hash) 
      self.grid(:column=>0,:row=>1,:sticky=>'news')
      @tagSel = TkTextTagSel.new(self)
      bind('Control-Key-a') {
        # From:
        # "Using Control-a to select all text in a text widget : TCL",
        # http://objectmix.com/tcl/35276-using-control-select-all-text-text-widget.html
        @tagSel.add('0.0', :end)
        Kernel.raise TkCallbackBreak
      }
      ##/ bind('Key-Return') {
      ##/   ans_( self.get )
      ##/   self.dialog.destroy
      ##/   goOn.value = '1'
      ##/ }

      #----  Scrollbars
      sy = Scrollbar.new(@frame)
      sy.grid(:column=>1,:row=>1,:sticky=>'ns')
      self.yscrollbar(sy)
      
      sx = Scrollbar.new(@frame)
      sx.grid(:column=>0,:row=>2,:sticky=>'ew')
      self.xscrollbar(sx)
      
      #----  Button-Cancel 
      @btn = Button.new(@frame, :text=>"Cancel").
        grid(:row=>3,:column=>0,:sticky=>'w')
      @btn.command { 
        self.dialog.destroy 
      }
      
      #----  Button-OK 
      @btn2 = Button.new(@frame, :text=>"OK").
        grid(:row=>3,:column=>0,:sticky=>'e')
        ## grid(:row=>3,:column=>0,:sticky=>'e',:columnspan=>2)
      @btn2.command { 
        got = self.get('0.0', 'end -1c')
        ans_( got )
        self.dialog.destroy
        goOn.value = '1'
      }

      @frame.grid_columnconfigure(0, :weight=>1)
      @frame.grid_columnconfigure(1, :weight=>0)
      @frame.grid_rowconfigure([0,2,3], :weight=>0)
      @frame.grid_rowconfigure(1, :weight=>1)
      @lbl.bind('Configure'){ 
        @lbl.wraplength =  TkWinfo.width(@frame) - 40
      }

      #----  Balloonhelp
      BalloonHelp.new(self,:text => help) if help

      self.focus
      ##Tk.update
    end # initialize
    
    def answer(  )
      @dialog.raise
      @goOn.wait
      @ans
    end # ans
    
    private
    
    def private____________________(  )
    end # private____________________
    
    def ans_( ans ) # Is there an easier way?
      @ans = ans.dup  if ans
    end # ans=
        
  end # class AskMultiLineD


  ##########################################################################
  ##########################################################################
  class SingleChoiceD < TkListbox
    include Tk::Tile
    CONF = nil  unless defined?(CONF)

    attr_accessor :dialog # in: "self.dialog


    ##########################################################################
    # See: TKXXS::single_choice
    def initialize( aryWithChoices, help=nil, hash=nil )
      aryWithChoices, help, hash = TKXXS_CLASSES.args_1(aryWithChoices, help, hash)

      @allChoices, @allClients, @allHelp = all_choices_clients_help(aryWithChoices)

      # Must always include:  :question, :help
      hash = {
        :question => "Choose one by single-click",
        :help => nil,
        :title => 'Choose one',
        :bd=>'2', # TODO: noch benötigt?
        :searchFieldHelp => "Enter RegExp for filter list here\n(not case sensitive)",
        :returnChoiceAndClient=>false
      }.merge(hash)

      # Necessary, because hash[:configSection]  is deleted later on
      # in args_2.

      CONF.section = hash[:configSection] if CONF && hash[:configSection]
    
      # help, hash, question, title = 
      #   TKXXS_CLASSES.args_2( help, hash, question, :title)
      help,hash,question,title,searchFieldHelp,@returnChoiceAndClient= 
        TKXXS_CLASSES.args_2(help,hash,question,:title,:searchFieldHelp,:returnChoiceAndClient)
      @allHelp ||= help

      teardownDone = false
      @ans = nil
      @goOn = goOn = TkVariable.new 
      # Because you cannot use instance-vars in procs. TODO: smarter way?

      @choices, @clients, @help = @allChoices, @allClients, @allHelp

      Tk.update # Show any calling widget first to make it lower than @dialog 
      #----  Toplevel: @dialog
      @dialog=Toplevel.new() {title(title)} 
      @dialog.geometry = CONF[:dialogGeom]  if CONF
      @dialog.bind('Destroy') {
        unless teardownDone
          goOn.value = '1' # !
          $tkxxs_.delete(object_id)
          if CONF
            CONF[:dialogGeom] = @dialog.geometry
            ##/ CONF.save
          end
          teardownDone = true
        end # unless
      }

      #----  Top Frame 
      @frame = Frame.new(@dialog) {padding "3 3 3 3"}.
        pack(:fill=>:both,:expand=>true)

      #----  Label
      @lbl = Label.new(@frame, :text=>question).
        grid(:sticky=>'ew')

      #----  Search-Entry 
      filterRegex = nil
      @entry = Entry.new(@frame) {|ent|
        grid(:sticky=>'ew')
        BalloonHelp.new(ent,:text => searchFieldHelp)
      }

      @entry.bind('Key-Return') { list_entry_chosen( goOn ) }
      @entry.bind('Key-Down') { self.focus }
      @entry.bind('Any-KeyRelease') {
        entryVal = @entry.get
        begin
          filterRegex = Regexp.new(entryVal, Regexp::IGNORECASE)
          populate_list( filterRegex )
        rescue RegexpError
          @lbl.text = "RegexpError"
        else
          @lbl.text = question
        end

      }
      @entry.focus
      
      # self = TkListbox
      # TODO: Kein Weg, das interne Padding zu vergrößern?? 
      super(@frame, hash) 
      self.grid(:column=>0,:sticky=>'news')
      self.bind('ButtonRelease-1') {
        list_entry_chosen( goOn )
      } 
      self.bind('Key-Return') {
        list_entry_chosen( goOn )
      } 

      #----  Scrollbar 
      scrollb = Scrollbar.new(@frame).grid(:column=>1,:row=>2,:sticky=>'ns')
      self.yscrollbar(scrollb)
      ##self.width = 0 # Width as needed
      ##self.height = 30 # TODO: Make configurable

      #----  Button-Cancel
      @btn = Button.new(@frame, :text=>"Cancel").
        grid(:row=>3,:column=>0,:sticky=>'w')
      @btn.command { 
        self.destroy 
      }

      @frame.grid_columnconfigure(0, :weight=>1)
      @frame.grid_columnconfigure(1, :weight=>0)
      @frame.grid_rowconfigure([0,1,3], :weight=>0)
      @frame.grid_rowconfigure(2, :weight=>1)

      #----  Balloonhelp
      if @help
        $tkxxs_[object_id] = {:listBalloonHelp=>@help.dup}
        list_balloonhelp
      end
      
      populate_list(nil)
      ##/ insert(0, *allChoices)
      ##/ self.selection_set 0
      update
    end # initialize
   
    def all_choices_clients_help( aryWithChoices, filterRegex=nil )
      return [ [], [], nil]  if !aryWithChoices || aryWithChoices.empty?

      case aryWithChoices[0].class.to_s
      when 'String'
        choices = aryWithChoices
        clients = choices.dup
        ## choicesAndClients = choices.zip(clients)
        help = nil
      when 'Array'
        choices, clients, tmpHelp = aryWithChoices.transpose 
        ## choicesAndClients = aryWithChoices
        help = tmpHelp if tmpHelp
      else
        raise "ERROR: aryWithChoices[0].class must be 'String' or 'Array',\n" + 
          "but is #{ aryWithChoices[0].inspect }.class = #{ aryWithChoices[0].class } "
      end

      [choices, clients, help]
    end # all_choices_clients_help
    
    def populate_list( filterRegex=nil )
      if filterRegex
        @choices, @clients, help = filtered_choices_clients_help( filterRegex )
      else
        @choices, @clients, help = @allChoices, @allClients, @allHelp
      end

      self.delete(0, :end)
      if @choices.empty?
        self.insert(0, [] )
      else
        self.insert(0, *@choices)
        self.selection_set(0)
        self.activate(0)
        ## puts sprintf("--DEBUG: $tkxxs_: %1s ", $tkxxs_.inspect)   #loe
        ## puts sprintf("--DEBUG: object_id: %1s ", object_id.inspect)   #loe
        ## puts sprintf("--DEBUG: help: %1s ", help.inspect)   #loe
        $tkxxs_[object_id][:listBalloonHelp].replace(help) if help
      end
    end # populate_list

    def filtered_choices_clients_help( filterRegex )
      choices = []
      clients = []
      help = []
      @allChoices.each_with_index {|ch, idx|
        if ch[filterRegex]
          choices << ch
          clients << @allClients[idx]
          help << @allHelp[idx] if @allHelp # ToDo: Gefährlich, falls nicht Array
        end
      }
      help = nil if help.empty? # +2010-02-15 Für pathchooser

      [choices, clients, help]
    end # filtered_choices_clients_help
    
    def list_entry_chosen( goOn )
      idx = self.curselection[0]
      ans_( idx )
      goOn.value = '1'
    end # list_entry_chosen
    
    def list_balloonhelp(  )
      bbb = BalloonHelp.new(self,
        :command=>proc{|x,y,bhelp,parent|
          idx = parent.nearest(y)
          bhelp.text($tkxxs_[object_id][:listBalloonHelp][idx])
        } 
      )
      nil
    end # list_balloonhelp

    ##################################################################
    # *Returns:* 
    # The right side of +aryWithChoices+ if :returnChoiceAndClient == +false+ (default),
    # both sides of +aryWithChoices+ if :returnChoiceAndClient == +true+,
    # +nil+, if 'Cancel' was clicked.
    def answer( )
      @goOn.wait
      self.dialog.destroy
      idx = @ans
      if @returnChoiceAndClient
        @ans = [ @choices[idx],  @clients[idx] ]
        res = @ans
      else
        res =  @ans  ?  @clients[idx]  :  nil
      end
      res
    end # ans
 
    ##/ def answer( opts={:both=>false} )
    ##/   @goOn.wait
    ##/   self.dialog.destroy
    ##/   idx = @ans
    ##/   if opts[:both]
    ##/     @ans = [ @choices[idx],  @clients[idx] ]
    ##/     res = @ans
    ##/   else
    ##/     res =  @ans  ?  @clients[idx]  :  nil
    ##/   end
    ##/   res
    ##/ end # ans
    
    private
    
    def private____________________(  )
    end # private____________________
    
    def ans_( ans ) # Is there an easier way?
      @ans = ans  if ans
    end # ans=
        
  end # class SingleChoiceD

  ##########################################################################
  ##########################################################################
  # MultiChoiceD has no search box like SingleChoiceD, up to now.
  class MultiChoiceD < TkListbox
    include Tk::Tile
    CONF = nil  unless defined?(CONF)
    attr_accessor :dialog # in: "self.dialog

    ##################################################################
    # See: TKXXS::multi_choice 
    def initialize( aryWithChoices, help=nil, hash=nil  )
      aryWithChoices, help, hash = TKXXS_CLASSES.args_1(aryWithChoices, help, hash)
      hash = {
        :selectmode => :multiple,
        :question => "Choose multiple:",
        :help => nil,
        :bd=>'2',
        :title=>'Please choose multiple...',
        :returnChoiceAndClient=>false
      }.merge(hash)

      # Necessary, because hash[:configSection]  is deleted later on
      # in args_2.
      CONF.section = hash[:configSection] if CONF && hash[:configSection]

      help,hash,question,title,searchFieldHelp,@returnChoiceAndClient= 
        TKXXS_CLASSES.args_2(help,hash,question,:title,:searchFieldHelp,:returnChoiceAndClient)

      ##/ question = hash[:question] unless question  
      ##/ help = hash[:help] unless help
      ##/ CONF.section = hash[:configSection]  if CONF
      ##/ 
      ##/ hash.delete :question
      ##/ hash.delete :help
      ##/ hash.delete :configSection
      
      teardownDone = false
      @ans = nil
      @goOn = goOn = TkVariable.new 
      # Because you cannot use instance-vars in procs. TODO: smarter way?
      case aryWithChoices[0].class.to_s
      when 'String'
        choices = aryWithChoices
        clients = choices.dup
        choicesAndClients = choices.zip(clients)
      when 'Array'
        choices, clients, tmpHelp = aryWithChoices.transpose 
        choicesAndClients = aryWithChoices
        help = tmpHelp if tmpHelp
      else
        raise "ERROR: aryWithChoices[0].class must be 'String' or 'Array',\nbut is #{ aryWithChoices[0].inspect }.class = #{ aryWithChoices[0].class } "
      end

      Tk.update # Show any calling widget first to make it lower than @dialog 
      #----  Toplevel: @dialog
      @dialog=Toplevel.new() {title(title)} 
      @dialog.geometry = CONF[:dialogGeom]  if CONF
      @dialog.bind('Destroy') {
        unless teardownDone
          goOn.value = '1' # !
          if CONF
            CONF[:dialogGeom] = @dialog.geometry
          end
          teardownDone = true
        end # unless
      }

      #----  Frame
      @frame = Frame.new(@dialog) {padding "3 3 3 3"}.
        pack(:fill=>:both,:expand=>true)

      #----  Label
      @lbl = Label.new(@frame){
        text question
        font $font if $font
        wraplength '400'
        justify 'left'
      }
      @lbl.grid(:sticky=>'news')
      
      #----  self = TkListbox 
      super(@frame, hash) 
      # TODO: Is there no way to increase the internal padding?? 
      #self.pack(:side=>:left,:expand=>1,:fill=>:both)
      self.grid(:sticky=>'news')
      
      #----  Scrollbar 
      scrollb = Scrollbar.new(@frame).
        grid(:row=>1,:column=>1,:sticky=>'news')
      self.yscrollbar(scrollb)

      #----  Button-Cancel
      @btn = Button.new(@frame, :text=>"Cancel").
        grid(:row=>2,:column=>0,:sticky=>'w')
      @btn.command { 
        self.destroy 
      }

      #----  Button-OK
      @btn = Button.new(@frame, :text=>"OK").
        grid(:row=>2,:column=>0,:sticky=>'e')
      @btn.command { 
        ans = []
        # TODO: Change to self.curselection like in SingleChoiceD
        begin
          choicesAndClients.each_with_index {|cc, idx|
            ans << cc  if self.selection_includes(idx)
          }
        rescue
          ans = []
        end
        ans_( ans )
        goOn.value = '1'
      } 

      @frame.grid_columnconfigure(0, :weight=>1)
      @frame.grid_columnconfigure(1, :weight=>0)
      @frame.grid_rowconfigure([0,2], :weight=>0)
      @frame.grid_rowconfigure(1, :weight=>1)
      insert(0, *choices)
      @lbl.bind('Configure'){ 
        @lbl.wraplength =  TkWinfo.width(@frame) - 40
      }

      #----  Balloonhelp
      if help
        BalloonHelp.new(self, 
                        :command=>proc{|x,y,bhelp,parent|
                          idx = parent.nearest(y)
                          bhelp.text( help[idx] )
                        }
        )
      end

      update
    end # initialize
    
    ##/ def answer(  )
    ##/   @goOn.wait
    ##/   self.dialog.destroy # includes grab("release")
    ##/   @ans = [] unless @ans
    ##/   @ans
    ##/ end # ans
    ##################################################################
    # *Returns:* 
    # * An Array of the chosen right sides of +aryWithChoices+ if :returnChoiceAndClient == +false+ (default),
    # * An Array of the chosen right and left sides of +aryWithChoices+ if :returnChoiceAndClient == +true+,
    # * +nil+, if 'Cancel' was clicked.
    # 
    def answer(  )
      @goOn.wait
      self.dialog.destroy
      @ans = []  unless @ans

      if @returnChoiceAndClient
        return @ans.transpose[0].zip(@ans.transpose[1]) # wg. help
      else
        return @ans.transpose[1]
      end
    end # ans
    
    private
    
    def private____________________(  )
    end # private____________________
    
    def ans_( ans ) # Is there an easier way?
      @ans = ans.dup  if ans
      ans
    end # ans=
        
  end # class MultiChoiceD
  
  class FileAndDirChooser
    include Tk::Tile
    CONF = nil  unless defined?(CONF)

    attr_accessor :dialog # in: "self.dialog

    ##########################################################################
    # This class provides the common functions for all dir- and file-choosers.
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
    #   * <tt>:mode</tt> - One of :choosedir, :openfile, :openfiles, :savefile.
    #   * <tt>:question</tt> - (String) Your question; +nil+ -> no question.
    #   * <tt>:title</tt> - (String) Title of the dialog window.
    #   * <tt>:defaultEntry</tt> - (String) Path, shown in the entry field. 
    #   * <tt>:validate</tt> - +true+ or +false+; if true, a valid path
    #     must be chosen, canceling the dialog is not possible.
    #   * <tt>:configSection</tt> - (any String, Integer or Float or nil) Not
    #     important. Sets the section in the config-file, where for example the
    #     window size and position is stored.
    def initialize( initialdir=nil,help=nil,hash=nil )
      initialdir, help, hash = 
        TKXXS_CLASSES.args_1( initialdir,help,hash )

      # Must always include:  :question, :help
      hash = {
        :mode=>:openfiles,
        :initialdir => Dir.pwd,
        :question => "Please choose the desired files:",
        :help => nil,
        :title => 'Choose Files',
        :defaultEntry => '',
        :validate=>nil,
      }.merge(hash)

      # Necessary, because hash[:configSection]  is deleted later on
      # in args_2.
      CONF.section = hash[:configSection] if CONF && hash[:configSection]
      help,hash,question,initialdirH,mode,defaultEntry,@validate = 
        TKXXS_CLASSES.args_2(help,hash,question,:initialdir,:mode,:defaultEntry,:validate)
      hash[:initialdir] = initialdir || initialdirH  # Tja, etwas umstaendlich

      @teardownDone = false
      @mode = mode
      @paths = nil
      @ans = nil
      @goOn = goOn = TkVariable.new 
      # Because you cannot use instance-vars in procs. TODO: smarter way?
      old_section = CONF.section
      CONF.section = nil # Following always stored in section=nil
      @recent_dirs_size = CONF[:recentDirsSize]
      @recent_files_size = CONF[:recentFilesSize]
      CONF.section = old_section


      Tk.update # Show any calling widget first to make it lower than @dialog

      #----  Toplevel: @dialog
      @dialog=Tk::Toplevel.new() {title(hash[:title])} 
      @dialog.geometry = CONF[:pathChooserGeom]  if CONF

      # This is neccessary for handling the close-button ('X') of the window
      @dialog.protocol(:WM_DELETE_WINDOW) {validate_and_leave}
      
      ##/ @dialog.bind('Destroy') {
      ##/   unless teardownDone
      ##/     goOn.value = '1' # !
      ##/     $tkxxs_.delete(object_id)
      ##/     if CONF
      ##/       CONF[:pathChooserGeom] = @dialog.geometry
      ##/       CONF.section = nil
      ##/       ##/ CONF.save
      ##/     end
      ##/     teardownDone = true
      ##/   end # unless
      ##/ }

      #----  Top Frame 
      @frame = Frame.new(@dialog) {padding "3 3 3 3"}.
        pack(:fill=>:both,:expand=>true)

      #----  Label (question)
      @qLbl = question_lbl(question,help).grid(:columnspan=>6,:sticky=>'nsew')

      #---- Labels ("Recent", "Favorites", ...)
      @recLbl = recent_lbl.grid(:column=>0,:columnspan=>2,:row=>1)
      @favLbl = favorite_lbl.grid(:column=>2,:columnspan=>2,:row=>1)
      @pasteLbl = paste_lbl.grid(:column=>4,:row=>1)

      #---- Buttons ("Dirs", "Files", "Browse", ...
      @recDirsBtn = recent_dirs_btn(hash).grid(:row=>2,:column=>0)
      @recFilesBtn = recent_files_btn.grid(:row=>2,:column=>1)
      @favDirsBtn = favorite_dirs_btn(hash).grid(:row=>2,:column=>2)
      @favFilesBtn = favorite_files_btn.grid(:row=>2,:column=>3)
      @pasteBtn = paste_btn.grid(:row=>2,:column=>4)
      @browseBtn = browse_btn(hash).grid(:row=>2,:column=>5)

      #---- Entry (Path)
      @entry = entry(defaultEntry).grid(:row=>3,:column=>0,:columnspan=>6,:sticky=>'ew')
      
      #---- Buttons ("Cancel", "OK")
      @cancelBtn = cancel_btn.grid(:row=>4,:column=>0)
      @okBtn = ok_btn.grid(:row=>4,:column=>5)
      
      #---- CheckButton ("Add to Favorites")
      @favChkLbl = favorite_chk_label.grid(:row=>4,:column=>1,:columnspan=>2,:sticky=>'e')
      @favDirsChkVal = nil
      @favDirsChk = add2favorites_dirs_chk.grid(:row=>4,:column=>3,:columnspan=>1)
      @favFilesChkVal = nil
      unless @mode == :choosedir
        @favFilesChk = add2favorites_files_chk.
          grid(:row=>4,:column=>4,:columnspan=>1,:sticky=>'w')
      end

      #---- Text (showing other path formats)
      @txt = text2.grid(:row=>5,:column=>0,:columnspan=>6,:sticky=>'sew')
      
      #---- grid_configure
      @frame.grid_columnconfigure([0,1,2,3,4,5], :weight=>1)
      @frame.grid_rowconfigure([0,1,2,3,4], :weight=>0)
      @frame.grid_rowconfigure([5], :weight=>1)

      @entry.focus
      Tk.update
      ##/ @dialog.raise
    end # initialize

    ##################################################################
    # For FileAndDirChooser, @validate is simply true or false. If
    # user presses "Cancel" or the close button ('X') in the upper
    # right, this is detected and user is informed by a message box.
    # Otherwise, all chosen paths already have been checked "inline",
    # hence no further validation is neccessary.
    def validate_and_leave(  )
      # path(s) is/are not valid.
      # TODO: Missleading method name; better(?): handle_invalid_path
      if @validate
        # Retry or completly exit the application
        ans =  Tk.messageBox(:icon=>:warning, :type=>:retrycancel,
          :title=>'Message',
          :message=>"INVALID ANSWER\n\nCANCEL will completely EXIT the application!"
          ## :detail=>"blablabla\n"*50
        )
        if ans == 'cancel'
          Tk.exit
          exit # Todo: nötig?
        end
      else
        set_paths(nil) # uses the invalid path
      end
    end # validate_and_leave

    def set_paths( paths )
      @paths = paths
      favorites_and_recent(paths)  if paths && !paths.empty?
      @goOn.value = '1'
      nil
    end # set_paths

    ##################################################################
    # When dialog is finished, always +set_paths+ must be called. For
    # 'Cancel', use set_paths(nil)
    # 
    # *Returns*: (String or Array or nil) Path(s); +nil+, if 'Cancel'
    # was clicked. 
    def answer(  )
      @dialog.raise  # Raise dialog above all other windows
      @goOn.wait # Force hold on of the dialog
      # Tear down
      unless @teardownDone  # TODO: not neccessary anymore?
        $tkxxs_.delete(object_id)
        if CONF   # Save settings (e.g., window size)
          CONF[:pathChooserGeom] = @dialog.geometry
          ##/ CONF.save
        end
        @teardownDone = true
        ##/ @goOn.value = '1'
        @dialog.destroy  # Remove dialog window
      end # unless
      Tk.update

      @paths # return the "answer"
    end # ans

    ##/ ##################################################################
    ##/ # Saves CONF!
    ##/ def dialog_destroy(  )
    ##/   unless @teardownDone
    ##/     $tkxxs_.delete(object_id)
    ##/     if CONF
    ##/       CONF[:pathChooserGeom] = @dialog.geometry
    ##/       CONF.section = nil
    ##/       ##/ CONF.save
    ##/     end
    ##/     @teardownDone = true
    ##/     ##/ @goOn.value = '1'
    ##/     @dialog.destroy
    ##/   end # unless
    ##/   nil
    ##/ end # dialog_destroy

    def question_lbl( question, help)
      lbl = Label.new(@frame, :text=>question){|w|
        BalloonHelp.new(w,:text=>help)
      }
    end # question_lbl
    
    def recent_lbl(  )
      lbl = Label.new(@frame, :text=>"Recent")
    end # recent_lbl
    
    def favorite_lbl(  )
      lbl = Label.new(@frame, :text=>"Favorites")
    end # favorite_lbl
    
    def paste_lbl(  )
      Label.new(@frame, :text=>"Clipboard")
    end # paste_lbl
    
    def recent_dirs_btn( hash )
      btn = Button.new(@frame, :text=>"Dirs"){|w|
        BalloonHelp.new(w,:text=>"Recent directories")
      }
      btn.command { 
        if CONF
          dirs = CONF[:recentDirs] || []
          ## dir = SingleChoiceD.new(dirs.sort).answer
          dir = SingleChoiceD.new(dirs).answer # unsorted
          if dir
            hash2 = hash.merge({:initialdir=>dir}).dup 
            ##/ filesStr = Tk.getOpenFile(hash2)
            ##/ set_paths( tks_result_to_ary( filesStr ) )
            case @mode
            ##/ when :choosedir;  set_paths(dir)
            when :choosedir;  validate_and_set_path( dir )
            when :openfiles;  choose(hash2)
            when :openfile;   choose(hash2)
            when :savefile;   choose(hash2)
            else; raise
            end # case
          end
        end # if CONF
      }
      btn
    end # recent_dirs_btn
    
    def recent_files_btn(  )
      btn = Button.new(@frame, :text=>"Files"){|w|
        BalloonHelp.new(w,:text=>"Recent files")
      }
      btn.command { 
        if CONF
          files = CONF[:recentFiles] || []
          ## filePath = SingleChoiceD.new(files.sort).answer
          filePath = SingleChoiceD.new(files).answer # unsorted
          if filePath
            case @mode
            when :choosedir
              validate_and_set_path(File.dirname(filePath))
            when :openfiles
              validate_and_set_path( filePath )
            when :openfile, :savefile
              validate_and_set_path( filePath )
            else; raise
            end # case
          end
        end # if CONF
      }
      btn
    end # recent_files_btn
    
    def favorite_dirs_btn( hash )
      btn = Button.new(@frame, :text=>"Dirs"){|w|
        BalloonHelp.new(w,:text=>"Favorite directories")
      }
      btn.command { 
        if CONF
          favDirs = CONF[:favoriteDirs] || []
          dir = SingleChoiceD.new(favDirs.sort).answer
          if dir
            hash2 = hash.merge({:initialdir=>dir}).dup
            ##/ filesStr = Tk.getOpenFile(hash2)
            ##/ set_paths( tks_result_to_ary( filesStr ) )
            case @mode
            when :choosedir; validate_and_set_path( dir )
            when :openfiles;  choose(hash2)
            when :openfile;   choose(hash2)
            when :savefile;   choose(hash2)
            else; raise
            end # case
          end
        end # if CONF
      }
      btn
    end # favorite_dirs_btn

    def favorite_files_btn(  )
      btn = Button.new(@frame, :text=>"Files"){|w|
        BalloonHelp.new(w,:text=>"Favorite files")
      }
      btn.command { 
        if CONF
          favFiles = CONF[:favoriteFiles] || []
          filePath = SingleChoiceD.new(favFiles.sort).answer
          if filePath
            case @mode
            when :choosedir
              validate_and_set_path(File.dirname(filePath))
            when :openfiles
              validate_and_set_path( [filePath] )
            when :openfile, :savefile
              validate_and_set_path( filePath )
            else; raise
            end # case
          end
        end # if CONF
      }
      btn
    end # favorite_files_btn
    
    def paste_btn(  )
      btn = Button.new(@frame, :text=>"Paste"){|w|
        BalloonHelp.new(w,:text=>"Paste clipboard to entry field")
      }
      btn.command { 
        @entry.delete(0, :end)
        begin
          clip = TkClipboard.get
        rescue => err # Clipboard no String
          clip = "Nothing usefull in clipboard"
        end
        @entry.insert(0, clip)
      }
      btn
    end # paste_btn

    def browse_btn( hash )
      btn = Button.new(@frame, :text=>"Browse"){|w|
        BalloonHelp.new(w,:text=>"Search for directory or file manually")
      }
      entry = @entry
      btn.command { 
        entryStr = @entry.get.strip.gsub('\\', '/').chomp('/')
        unless entryStr.empty?
          if File.directory?(entryStr)
            hash[:initialdir] = entryStr
          elsif File.file?(entryStr)
            hash[:initialdir] = File.dirname(entryStr)
          end
        end
        choose(hash) 
      }
    end # browse_btn
    
    def entry( defaultEntry )
      entry = Entry.new(@frame) {|ent|
        BalloonHelp.new(ent,:text=>"Type or paste a path here.")
      }
      entry.insert(0, defaultEntry)
      entry.bind('Key-Return') { use_entry(@entry.get) }
    end # entry
    
    def cancel_btn(  )
      btn = Button.new(@frame, :text=>"Cancel"){|w|
        BalloonHelp.new(w,:text=>"Do nothing")
      }
      btn.command { 
        validate_and_leave
        ###set_paths(nil)
        ##/ dialog_destroy 
      }
      btn
    end # cancel_btn
    
    def ok_btn(  )
      btn = Button.new(@frame, :text=>"Use entry"){|w|
        BalloonHelp.new(w,:text=>"Use path from entry box")
      }
      btn.command { use_entry(@entry.get) }
    end # ok_btn
    
    def use_entry( str )
      str = str.strip.gsub('\\', '/').chomp('/')
      validate_and_set_path( str )
    end # use_entry
    
    def validate_and_set_path( str )
      case @mode
      when :choosedir
        if File.directory?(str)
          set_paths(str)
        elsif File.file?(str)
          set_paths( File.dirname(str) )
        else
          @txt.replace('0.0', :end, %Q<"#{ str }" is no > +
            "valid directory, please choose a valid one!")
          @entry.focus
        end
      when :openfiles, :openfile
        if File.file?(str)
          @mode == :openfile ? set_paths(str) : set_paths([str])
        else
          @txt.replace('0.0', :end, %Q<"#{ str }" is no > +
            "valid file, please choose a valid one!")
          @entry.focus
        end
      when :savefile
        if @validate
          dir = File.dirname(str)
          if File.directory?(dir)
            set_paths(str)
          else
            @txt.replace('0.0', :end, %Q<"#{ dir }" is no > +
              "valid directory, please choose a valid one!")
            @entry.focus
          end
        else
          # if file does not exist: create file and dir
          set_paths(str)
        end
      else; raise
      end # case
      nil
    end # validate_and_set_path

    def favorite_chk_label(  )
      lbl = Label.new(@frame, :text=>"Add to favorites")
    end # favorite_chk_label

    def add2favorites_dirs_chk(  )
      favChkVar = TkVariable.new(0)
      favChk = CheckButton.new(@frame) {|w|
        text 'dirs'
        variable favChkVar
        ##/ onvalue 'metric'; offvalue 'imperial'
        BalloonHelp.new(w,:text=>"If checked, the path(s) of files or directories you are going to choose will be added to the favorite directories.")
      }
      favChk.command { self.fav_dirs_chk_changed(favChkVar.value) }
      favChk
    end # add2favorites_dirs_chk
    
    def add2favorites_files_chk(  )
      favChkVar = TkVariable.new(0)
      favChk = CheckButton.new(@frame) {|w|
        text 'files'
        variable favChkVar
        ##/ onvalue 'metric'; offvalue 'imperial'
        BalloonHelp.new(w,:text=>"If checked, the files(s) you are going to choose will be added to the favorite files.")
      }
      favChk.command { self.fav_files_chk_changed(favChkVar.value) }
      favChk
    end # add2favorites_files_chk

    def fav_dirs_chk_changed( val )
      @favDirsChkVal =  val == '1'  ?  true  :  false
      @favDirsChkVal
    end # fav_dirs_chk_changed

    def fav_files_chk_changed( val )
      @favFilesChkVal =  val == '1'  ?  true  :  false
      @favDirsChk.invoke if @favFilesChkVal && !@favDirsChkVal
      @favFilesChkVal
    end # fav_files_chk_changed
    
    def text2(  )
      txt = TkText.new(@frame)
      tagSel = TkTextTagSel.new(txt)
      txt.bind('Control-Key-a') {
        # From: "Using Control-a to select all text in a text widget : TCL", http://objectmix.com/tcl/35276-using-control-select-all-text-text-widget.html
        tagSel.add('0.0', :end)
        Kernel.raise TkCallbackBreak
      }
      txt
    end # text2
    
    def favorites_and_recent( paths )
      fav_dirs(paths)  if @favDirsChkVal  # For any mode
      fav_files(paths) if @favFilesChkVal # For any mode but :choosedir; no @favFilesChk for chooseDirectory
      recent_dirs(paths)
      recent_files(paths) unless @mode == :choosedir
      CONF.save
      nil
    end # favorites_and_recents
    
    def fav_dirs( paths )
      return nil  unless paths
      paths = paths.dup
      favDirs = CONF[:favoriteDirs] || []
      paths = [paths] if paths.class == String
      paths.map! {|p|
        File.file?(p)  ?  File.dirname(p) :  p
      }
      favDirs.concat(paths)
      favDirs.uniq!
      CONF[:favoriteDirs] = favDirs
      favDirs
    end # fav_dirs
    
    def fav_files( paths )
      return nil  unless paths
      paths = paths.dup
      favFiles = CONF[:favoriteFiles] || []
      paths = [paths] if paths.class == String
      favFiles.concat(paths)
      favFiles.uniq!
      CONF[:favoriteFiles] = favFiles
      favFiles
    end # fav_files
    
    def recent_dirs( paths )
      return nil  unless paths
      paths = paths.dup
      dirs = CONF[:recentDirs] || []
      paths = [paths] if paths.class == String
      paths.map! {|p|
        p = File.file?(p)  ?  File.dirname(p) :  p
        p = File.directory?(p)  ?  p  :  nil
        p
      }
      paths.compact!
      dirs = paths + dirs
      dirs.uniq!
      CONF[:recentDirs] = dirs[0, @recent_dirs_size ]
      dirs
    end # recent_dirs
    
    def recent_files( paths)
      return nil  unless paths
      paths = paths.dup
      files = CONF[:recentFiles] || []
      paths = [paths] if paths.class == String
      files = paths + files
      files.uniq!
      CONF[:recentFiles] = files[0, @recent_files_size ]
      files
    end # recent_files
    
    def tks_result_to_ary( filesListStr )
      paths = []
      if filesListStr[0,1]=='{'
        filesListStr.scan( / \{   ( [^\}]+ )   \} /x) {
          paths << $1
        }
      else
        paths = filesListStr.split(' ')
      end
      
      paths
    end # tks_result_to_ary
  end # class FileAndDirChooser

  ##########################################################################
  ##########################################################################
  class ChooseDirD < FileAndDirChooser

    ##################################################################
    # See: TKXXS.choose_dir
    def initialize( initialdir=nil,help=nil,hash=nil )
      initialdir, help, hash = 
        TKXXS_CLASSES.args_1( initialdir,help,hash )
      hash = {
        :mode => :choosedir,
        :question=>"Please choose a directory",
        :title=>"Choose Directory",
      }.merge(hash)
      super(initialdir, help, hash)
    end

    def choose( hash )
      dirStr = Tk.chooseDirectory( hash )
      path =  dirStr.empty?  ?  nil  :  dirStr

      if path
        set_paths( path )
      else
        validate_and_leave
      end
      nil
    end # choose

    alias :path :answer
  end # class ChooseDirD

  ##########################################################################
  ##########################################################################
  class OpenFilesD < FileAndDirChooser
    ##################################################################
    # See: TKXXS.open_files
    def initialize( initialdir=nil,help=nil,hash=nil )
      initialdir, help, hash = 
        TKXXS_CLASSES.args_1( initialdir,help,hash )
      hash = {
        :mode => :openfiles,
        :question=>"Please choose the desired files",
        :title=>"Open Files",
        :filetypes => [['All files','*']],
        :multiple=>true 
      }.merge(hash)
      super(initialdir, help, hash)
    end

    def choose( hash )
      filesStr = Tk.getOpenFile(hash)
      if filesStr
        set_paths( tks_result_to_ary( filesStr ) )
      else
        validate_and_leave
      end
      nil
    end # choose

    alias :paths :answer
  end # class OpenFilesD

  ##########################################################################
  ##########################################################################
  class OpenFileD < FileAndDirChooser

    ##################################################################
    # See: TKXXS.open_file
    def initialize( initialdir=nil,help=nil,hash=nil )
      initialdir, help, hash = 
        TKXXS_CLASSES.args_1( initialdir,help,hash )
      hash = {
        :mode => :openfile,
        :question=>"Please choose the desired file",
        :title=>"Open File",
        :filetypes => [['All files','*']],
        :multiple=>false 
      }.merge(hash)
      super(initialdir, help, hash)
    end

    def choose( hash )
      fileStr = Tk.getOpenFile(hash)
      if fileStr
        set_paths( fileStr )
      else
        validate_and_leave
      end
      nil
    end # choose

    alias :path :answer
  end # class OpenFilesD

  ##########################################################################
  ##########################################################################
  class SaveFileD < FileAndDirChooser

    ##################################################################
    # See: TKXXS.save_file
    def initialize( initialdir=nil,help=nil,hash=nil )
      initialdir, help, hash = 
        TKXXS_CLASSES.args_1( initialdir,help,hash )
      hash = {
        :mode => :savefile,
        :question=>"Please choose, where to save the file:",
        :title=>"Save File As...",
        :filetypes => [['All files','*']],
        :initialfile => 'Untitled', # Default filename, extension will be added automatically by filetypes-setting
        :defaultextension => nil,
      }.merge(hash)
      super(initialdir, help, hash)
    end

    def choose( hash )
      fileStr = Tk.getSaveFile(hash)
      path =  fileStr.empty?  ?  nil  :  fileStr
      if path
        set_paths( path )
      else
        validate_and_leave
      end
      nil
    end # choose
    
    alias :path :answer
  end # class SaveFileD

  ##/ ##########################################################################
  ##/ ##########################################################################
  ##/ class OpenFileD < OpenFilesD
  ##/   
  ##/   def initialize( initialdir=nil,help=nil,hash=nil )
  ##/     initialdir, help, hash = 
  ##/       TKXXS_CLASSES.args_1( initialdir,help,hash )
  ##/ 
  ##/     # Must always include:  :question, :help, :configSection
  ##/     hash = {
  ##/       :initialdir => Dir.pwd,
  ##/       :question => "Please choose the desired file:",
  ##/       :help => nil,
  ##/       :configSection => nil,
  ##/       :filetypes => [['All files','*']],
  ##/       :multiple => 0,
  ##/     }.merge(hash)
  ##/ 
  ##/     super(initialdir,help,hash)
  ##/   end # initialize
  ##/   
  ##/   def path(  )
  ##/     CONF.section = nil  if CONF
  ##/     @paths[0]
  ##/   end # paths
  ##/   alias :answer :path
  ##/ end # class OpenFileD
 

end # class 


