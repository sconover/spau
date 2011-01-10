$LOAD_PATH << "lib"

require "rubygems"
require "minitest/spec"
require "pp"

require "wrong"
require "wrong/adapters/minitest"
require "wrong/message/test_context"
require "wrong/message/string_comparison"
Wrong.config[:color] = true

require "harmony"

module Kernel
  alias_method :regarding, :describe
  
  def xdescribe(str)
    puts "x'd out 'describe \"#{str}\"'"
  end
end

def write_file(f, str)
  File.open(f, "w"){|f|f<<str}
end

MiniTest::Unit.autorun