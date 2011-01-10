require "test/helper"
require "compress_and_inline_js_and_css"

describe "js compression" do
  it "compresses js files and inlines them" do
    write_file("/tmp/add.js", <<-JAVASCRIPT)
      function addNumbers(x, y) {
        var OH_HEY_IM_NOT_USED = 1;
        return x + y;
      }
    JAVASCRIPT
    
    write_file("/tmp/subtract.js", <<-JAVASCRIPT)
      function subtractNumbers(y, x) {
        return y - x;
      }
    JAVASCRIPT
    
    write_file("/tmp/test.html", <<-HTML)
      <html>
        <head>
          <script src="add.js"></script>
          <script src="subtract.js"></script>
          <script>
            function doCalculations() {
              return subtractNumbers(addNumbers(7, 5), 3)
            }
          </script>
        </head>
        <body>
          <b>Hi I'm Html</b>
        <body>
      </html>
    HTML
    
    result = SPAU::compress_and_inline("/tmp/test.html", "/tmp")

    deny{ result.include?("add.js") }
    deny{ result.include?("subtract.js") }
    
    assert{ result.include?("addNumbers") }
    assert{ result.include?("subtractNumbers") }
    deny{ result.include?("OH_HEY_IM_NOT_USED") }
    
    assert{ result.include?("<b>Hi I'm Html</b>") }

    assert{ Harmony::Page.new(result).execute_js("doCalculations()") == 9 }
  end
end