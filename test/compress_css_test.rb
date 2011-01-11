require "test/helper"
require "compress_and_inline_js_and_css"

describe "css compression" do
  it "compresses css files and inlines them" do
    write_file("/tmp/red.css", <<-CSS)
      .red{background-color:red;}
    CSS
    
    write_file("/tmp/blue.css", <<-CSS)
      /*
      HERE'S A COMMENT
      */
      .blue{background-color:blue;}
    CSS
    
    write_file("/tmp/test.html", <<-HTML)
      <html>
        <head>
          <link rel="stylesheet" type="text/css" media="all" href="red.css" />
          <meta>A</meta>
          <link rel="stylesheet" type="text/css" media="all" href="blue.css" />
        </head>
        <body>
          <div id="redDiv" class="red">RRR</div>
          <div id="blueDiv" class="blue">BBB</div>
          <b>Hi I'm Html</b>
        <body>
      </html>
    HTML
    
    result = SPAU::compress_and_inline_css("/tmp/test.html", "/tmp")

    deny{ result.include?("red.css") }
    deny{ result.include?("blue.css") }
    
    assert{ result.include?("background-color:red") }
    assert{ result.include?("background-color:blue") }
    deny{ result.include?("HERE'S A COMMENT") }
    
    deny{ result.include?("<link") }
    
    assert{ result.include?("<meta>A</meta>") }
    assert{ result.include?("<b>Hi I'm Html</b>") }
    
    #can't get computed style in harmony/johnson
        puts %{


COMPRESSED CSS FROM CSS FILES:
#{result}


        }
  end
  
  it "compresses css code from style tags" do
    write_file("/tmp/test.html", <<-HTML)
      <html>
        <head>
          <style type='text/css'>
            .red{background-color:red;}
          </style>
          <meta>A</meta>
          <style type='text/css'>
            /*
            HERE'S A COMMENT
            */
            .blue{background-color:blue;}
          </style>
        </head>
        <body>
          <div id="redDiv" class="red">RRR</div>
          <div id="blueDiv" class="blue">BBB</div>
          <b>Hi I'm Html</b>
        <body>
      </html>
    HTML
    
    result = SPAU::compress_and_inline_css("/tmp/test.html", "/tmp")

    assert{ result.include?("background-color:red") }
    assert{ result.include?("background-color:blue") }
    deny{ result.include?("HERE'S A COMMENT") }
    
    assert{ result.include?("<meta>A</meta>") }
    assert{ result.include?("<b>Hi I'm Html</b>") }  
    
    puts %{

    
COMPRESSED CSS FROM STYLE TAGS:
#{result}

      
    }
  end
end