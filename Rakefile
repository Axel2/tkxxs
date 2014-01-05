# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :seattlerb

# Hoe.plugin :compiler
# Hoe.plugin :doofus
# Hoe.plugin :email
# Hoe.plugin :gem_prelude_sucks
# Hoe.plugin :git
# Hoe.plugin :history
# Hoe.plugin :inline
# Hoe.plugin :isolate
# Hoe.plugin :minitest
# Hoe.plugin :perforce
# Hoe.plugin :racc
# Hoe.plugin :rcov
# Hoe.plugin :rubyforge
# Hoe.plugin :seattlerb

Hoe.spec "tkxxs" do
  developer "Axel Friedrich", "axel dod friedrich underscore smail ad gmx dod de"
  license "MIT"

  spec_extras[:rdoc_options] = proc do |ary|
    #rdoc.bat -t TKXXS --force-update -f hanna --op ./doc  -x lib/tkxxs/tkxxs_classes.rb -x lib/tkxxs/samples --main ./README.txt ./README.txt ./lib/tkxxs.rb


    ary.push "-x", "lib/tkxxs/tkxxs_classes.rb"
    ary.push "-x", "lib/tkxxs/samples"
    ary.push "-x", "lib/tkxxs/conf.rb"
  end

  dependency "Platform", "~> 0.4.0"
end

# vim: syntax=ruby


