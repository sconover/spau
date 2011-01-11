require "fileutils"

module SPAU
  YUI_COMPRESSOR_PATH = File.join(File.dirname(__FILE__), "..", "yuicompressor.jar")
  SINGLE_LINE_SCRIPT_REGEX = /(<script(.*)?<\/script>)/
  MULTI_LINE_SCRIPT_REGEX = /(<script(.*)?<\/script>)/m
  
  def self.compress_and_inline_js_and_css!(html_file, base_dir=".")
    File.open(html_file + ".tmp", "w"){|f|f << compress_and_inline_js(html_file, base_dir)}
    FileUtils.mv(html_file + ".tmp", html_file)
    
    File.open(html_file + ".tmp", "w"){|f|f << compress_and_inline_css(html_file, base_dir)}
    FileUtils.mv(html_file + ".tmp", html_file)
  end
  
  def self.compress_and_inline_js(html_file, base_dir=".", files_to_exclude=[])
    html = File.read(html_file)
    compress_and_inline_type(
      :type => "js",
      :html => html,
      :base_dir => base_dir,
      :single_line_regex => /<script(.*?)<\/script>/,
      :multi_line_regex => /(<script(.*?)<\/script>)/m,
      :tag_begin_regex => /<script(.*?)>/,
      :tag_end_regex => /<\/script>/,
      :file_tag_regex => /<script.*? src(.*?)<\/script>/,
      :file_regex => /src=/,
      :file_capture_regex => /src=["'](.*?)["']/,
      :replacement_begin_tag => "<script>",
      :replacement_end_tag => "</script>",
      :files_to_exclude => files_to_exclude
    )
  end
  
  def self.compress_and_inline_css(html_file, base_dir=".")
    html = File.read(html_file)
    compress_and_inline_type(
      :type => "css",
      :html => html,
      :base_dir => base_dir,
      :single_line_regex => /<style(.*?)<\/style>/,
      :multi_line_regex => /(<style(.*?)<\/style>)/m,
      :tag_begin_regex => /<style(.*?)>/,
      :tag_end_regex => /<\/style>/,
      :file_tag_regex => /(<link(.*?)<\/link>|<link(.*)?\/>)/,
      :file_regex => /href=/,
      :file_capture_regex => /href=["'](.*?)["']/,
      :replacement_begin_tag => "<style type='text/css'>",
      :replacement_end_tag => "</style>",
      :files_to_exclude => []
    )
  end
  
  private
  def self.compress_and_inline_type(args)
    all_str = ""
    
    FileUtils.cd(args[:base_dir]) do
      found = true
      remaining_file_contents = args[:html]
      while (found)
        found = false
        if script_tag_contents_match=(remaining_file_contents.match(args[:file_tag_regex]) || 
                                      remaining_file_contents.match(args[:single_line_regex]) || 
                                      remaining_file_contents.match(args[:multi_line_regex]))
          found = true
          whole_script_tag = script_tag_contents_match[0]
          inner = script_tag_contents_match.captures.first

          if (whole_script_tag.match(/^(.*)?>/)[0].strip =~ args[:file_regex])
            relative_file_path = whole_script_tag.match(args[:file_capture_regex]).captures.first
            unless (args[:files_to_exclude].include?(relative_file_path))
              all_str << "\n\n"
              all_str << File.read(relative_file_path)
            end
          else
            all_str << "\n\n"
            all_str << inner.gsub(args[:tag_begin_regex], "").gsub(args[:tag_end_regex], "")
          end

          remaining_file_contents = script_tag_contents_match.post_match
        end
      end
    end

    File.open("/tmp/temp_all.#{args[:type]}", "w"){|f|f<<all_str}
    compress("/tmp/temp_all.#{args[:type]}", "/tmp/temp_all_min.#{args[:type]}", args[:type])
    
    all_str_compressed = File.read("/tmp/temp_all_min.#{args[:type]}")


    result = args[:html].gsub(args[:file_tag_regex]) do |file_tag_match|
      relative_file_path = file_tag_match.match(args[:file_capture_regex]).captures.first
      if args[:files_to_exclude].include?(relative_file_path)
        file_tag_match
      else
        ""
      end
    end
    
    result.gsub!(args[:single_line_regex]) {|str| str.match(args[:file_capture_regex]) ? str : ""}
    result.gsub!(args[:multi_line_regex]) {|str| str.match(args[:file_capture_regex]) ? str : ""}
    result.sub!("</head>", "#{args[:replacement_begin_tag]}\n#{all_str_compressed}\n#{args[:replacement_end_tag]}\n</head>")

    result

  end
  
  def self.compress(source_in, compressed_out, type)
    system("java -jar #{YUI_COMPRESSOR_PATH} --type #{type} #{source_in} -o #{compressed_out}") || raise("#{type} compression didn't work")
  end
end