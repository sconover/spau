require "fileutils"

module SPAU
  YUI_COMPRESSOR_PATH = File.join(File.dirname(__FILE__), "..", "yuicompressor.jar")
  SINGLE_LINE_SCRIPT_REGEX = /(<script(.*)?<\/script>)/
  MULTI_LINE_SCRIPT_REGEX = /(<script(.*)?<\/script>)/m
  
  def self.compress_and_inline(html_file, base_dir=".")
    all_js = ""
    file_contents = File.read(html_file)

    lines = file_contents.split("\n")

    FileUtils.cd(base_dir) do
      pos = 0
      found = true
      while (found && pos<file_contents.length)
        found = false
        remaining_file_contents = file_contents.slice(pos..-1)
        if script_tag_contents_match=(remaining_file_contents.match(SINGLE_LINE_SCRIPT_REGEX) || remaining_file_contents.match(MULTI_LINE_SCRIPT_REGEX))
          found = true
          whole_script_tag = script_tag_contents_match[0]
          inner = script_tag_contents_match.captures.first

          if (whole_script_tag.match(/^(.*)?>/)[0].strip =~ /src=/)
            js_file_name = whole_script_tag.match(/src=["'](.*)["']/).captures.first
            all_js << "\n\n"
            all_js << File.read(js_file_name)
          else
            all_js << "\n\n"
            all_js << inner.gsub(/<script(.*)?>/, "").gsub(/<\/script>/, "")
          end
          
          pos += whole_script_tag.length
        end
      end
    end

    File.open("/tmp/temp_all.js", "w"){|f|f<<all_js}
    compress_js("/tmp/temp_all.js", "/tmp/temp_all_min.js")
    
    all_js_compressed = File.read("/tmp/temp_all_min.js")
    
    file_contents.gsub!(SINGLE_LINE_SCRIPT_REGEX, "")
    file_contents.gsub!(MULTI_LINE_SCRIPT_REGEX, "")
    file_contents.sub!("</head>", "<script>\n#{all_js_compressed}\n</script>\n</head>")
    
    file_contents
  end
  
  private
  def self.compress_js(source_in_js, compressed_out_js)
    system("java -jar #{YUI_COMPRESSOR_PATH} --type js #{source_in_js} -o #{compressed_out_js}") || raise("js compression didn't work")
  end
end