require "rubygems"
require "nokogiri"
require "benchmark"
require "fileutils"

module SPAU
  YUI_COMPRESSOR_PATH = File.join(File.dirname(__FILE__), "..", "yuicompressor.jar")
  
  def self.compress_and_inline_js_and_css!(html_file, base_dir=".", files_to_exclude=[], compress_js=true)
    File.open(html_file + ".tmp", "w"){|f|f << compress_and_inline_css(html_file, base_dir)}
    FileUtils.mv(html_file + ".tmp", html_file)

    File.open(html_file + ".tmp", "w"){|f|f << compress_and_inline_js(html_file, base_dir, files_to_exclude, compress_js)}
    FileUtils.mv(html_file + ".tmp", html_file)
  end
  
  def self.compress_and_inline_js(html_file, base_dir=".", files_to_exclude=[], compress=true)
    html = File.read(html_file)
    compress_and_inline_type(
      :type => "js",
      :html => html,
      :base_dir => base_dir,
      :files_to_exclude => files_to_exclude,
      :file_tag_name => "script",
      :file_attr => "src",
      :inline_tag_name => "script",
      :compress => compress
    )
  end
  
  def self.compress_and_inline_css(html_file, base_dir=".")
    html = File.read(html_file)
    compress_and_inline_type(
      :type => "css",
      :html => html,
      :base_dir => base_dir,
      :files_to_exclude => [],
      :file_tag_name => "link",
      :file_attr => "href",
      :inline_tag_name => "style",
      :compress => true
    )
  end
  
  private
  
  def self.compress_and_inline_type(args)
    all_str = ""
    result = nil
    FileUtils.cd(args[:base_dir]) do
    
      doc = Nokogiri::HTML(args[:html])
      doc.xpath("//#{args[:file_tag_name]}|//#{args[:inline_tag_name]}").each do |element|
        if element.name == args[:file_tag_name] && file=element.get_attribute(args[:file_attr])
          unless args[:files_to_exclude].include?(file)
            all_str << "\n\n"
            all_str << File.read(file)
            element.remove
          end
        else
          all_str << "\n\n"
          all_str << element.content
          element.remove
        end
      end
      
      result = doc.to_html
    end
    
    if (args[:compress])
      File.open("/tmp/temp_all.#{args[:type]}", "w"){|f|f<<all_str}
      compress("/tmp/temp_all.#{args[:type]}", "/tmp/temp_all_min.#{args[:type]}", args[:type])
    
      all_str = File.read("/tmp/temp_all_min.#{args[:type]}")
    end
    
    result.sub!("</head>", "<#{args[:inline_tag_name]}>\n#{all_str}\n</#{args[:inline_tag_name]}>\n</head>")
    result
  end
  
  def self.compress(source_in, compressed_out, type)
    duration = Benchmark.realtime {
      system("java -jar #{YUI_COMPRESSOR_PATH} --type #{type} #{source_in} -o #{compressed_out}") || raise("#{type} compression didn't work")
    }
    $stderr.puts "#{type} sizes:  original:#{File.size(source_in)} compressed:#{File.size(compressed_out)} time:#{(duration*1000).to_i}ms" 
  end
end