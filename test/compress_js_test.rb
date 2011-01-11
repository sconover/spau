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
          <meta>A</meta>
          <script src="add.js"></script>
          <meta>B</meta>
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
    
    result = SPAU::compress_and_inline_js("/tmp/test.html", "/tmp")

    deny{ result.include?("add.js") }
    deny{ result.include?("subtract.js") }
    
    assert{ result.include?("addNumbers") }
    assert{ result.include?("subtractNumbers") }
    deny{ result.include?("OH_HEY_IM_NOT_USED") }
    
    assert{ result.gsub(/\s+/, "").include?("<meta>A</meta><meta>B</meta>") }
    assert{ result.include?("<b>Hi I'm Html</b>") }

    assert{ Harmony::Page.new(result).execute_js("doCalculations()") == 9 }

        puts %{


COMPRESSED JS FROM JS SCRIPT FILES:
#{result}


        }

  end
  
  it "compresses js code from script tags" do
    write_file("/tmp/test.html", <<-HTML)
      <html>
        <head>
          <meta>A</meta>
          <script>
            function addNumbers(x, y) {
              var OH_HEY_IM_NOT_USED = 1;
              return x + y;
            }
          </script>
          <meta>B</meta>
          <script>
            function subtractNumbers(y, x) {
              return y - x;
            }
          </script>

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
    
    result = SPAU::compress_and_inline_js("/tmp/test.html", "/tmp")

    assert{ result.include?("addNumbers") }
    assert{ result.include?("subtractNumbers") }
    deny{ result.include?("OH_HEY_IM_NOT_USED") }
    
    assert{ result.gsub(/\s+/, "").include?("<meta>A</meta><meta>B</meta>") }
    assert{ result.include?("<b>Hi I'm Html</b>") }

    assert{ Harmony::Page.new(result).execute_js("doCalculations()") == 9 }
    
        puts %{


COMPRESSED JS FROM INLINE SCRIPTS:
#{result}


        }

  end
end