require "fileutils"

module SPAU
  YUI_COMPRESSOR_PATH = File.join(File.dirname(__FILE__), "..", "yuicompressor.jar")
  SCRIPT_FILE_REFERENCE = /<script(.*)?src(.*)?<\/script>/
  
  def self.compress_and_inline(html_file, base_dir=".")
    all_js = ""
    lines = File.read(html_file).split("\n")
    FileUtils.cd(base_dir) do
      script_files = lines.select{|line|line =~ SCRIPT_FILE_REFERENCE}.
                           map{|line|line.match(/src=["'](.*)\.js["']/).captures.first}
      all_js = script_files.map{|f|File.read(f + ".js")}.join("\n\n")
    end

    File.open("/tmp/temp_all.js", "w"){|f|f<<all_js}
    compress_js("/tmp/temp_all.js", "/tmp/temp_all_min.js")
    
    all_js_compressed = File.read("/tmp/temp_all_min.js")

    lines_without_script_file_tags = lines.reject{|line|line =~ SCRIPT_FILE_REFERENCE}.join("\n")
    lines_without_script_file_tags.sub!("</head>", "<script>\n#{all_js_compressed}\n</script>\n</head>")
    
    lines_without_script_file_tags
  end
  
  private
  def self.compress_js(source_in_js, compressed_out_js)
    system("java -jar #{YUI_COMPRESSOR_PATH} --type js #{source_in_js} -o #{compressed_out_js}") || raise("js compression didn't work")
  end
end