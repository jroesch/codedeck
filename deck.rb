require 'pygments'
require 'mustache'

class FileParser

  attr_accessor :config, :lines

  def initialize(file)
    @lines = File.read(file).lines.to_a
    @confi = @lines[0,1]
    @comment = ["/*", "*/"]
    @multiline = true 
    @comment_regex = /\/\*([^\*]|\*[^\\])*\*\//
    @directive_regex = /\-\-([^\-]|-[^\-])*\-\-/ 
    @slide_regex = /slide\s*\d+/
  end
  
  def parse
    lines = @lines[1, @lines.length]
    parsed_lines = []
    current_slide = []
    lines.each do |line|
      if found_comment = extract_comment(line)
        if found_directive = extract_directive(found_comment)
          if found_directive =~ @slide_regex
            if current_slide != []
              parsed_lines << current_slide
              current_slide = []
            end
          end   
        else
          current_slide << line
        end
      else
        current_slide << line
      end
    end
    parsed_lines << current_slide
  end 
  

  def handle(directive)
    puts directive 
  end

  def is_comment?(line)
    if @multiline
      (line.strip =~ @comment_regex) == 0     
    else
      puts "Not Working with Single Line comments "
      exit()
    end
  end

  def is_directive?(line)
    (line.strip =~ @directive_regex) == 0
  end
  
  # Both extract_xxx functions rely on the behavior of Ruby if's
  # an if without and else will always return nil on the false path
  def extract_comment(line)
    if is_comment? line
      clean_line = line.strip
      start_offset = comment_start.length
      end_offset = clean_line.length - comment_end.length - 1
      clean_line[start_offset..end_offset].strip
    end
  end

  def extract_directive(line)
    if is_directive? line
      clean_line = line.strip
      clean_line[2, clean_line.length - 4].strip
    end
  end

  def comment_start
    @comment[0]
  end

  def comment_end
    @comment[1]
  end
end

class Highlighter 
  def initialize(file)
    @file = file
    @file_parser = FileParser.new file
  end

  attr_accessor :result, :file_parser

  def highlight
    code = @file_parser.parse
    processed_code = code.map do |chunk|
      if chunk.is_a? Array
        Pygments.highlight(chunk.join, :lexer => 'scala')
      else
        Pygments.highlight(chunk.to_s, :lexer => 'scala')
      end
    end
    processed_code
  end

  def css
    Pygments.css
  end
end

class Presentation
  def initialize(fname, output_dir) 
    @file_name = name
    @output_dir = output_dir
  end

  def generate
    hl = Highlighter.new(@file_name)
    slide_template = template_for "slide"
    presentation_template = template_for "presentation"
    slides = hl.highlight.map do |slide|
      Mustache.render slide_template, :content => slide
    end
    joined_slides = slides.join("\n")
    presentation = Mustache.render presentation_template, :slides => joined_slides,
                                                          :title  => "Test",
                                                          :css    => "code.css"
    File.write("#{Dir.pwd}/output.html", presentation)
    presentation
  end
  
  def output(path, content)
  end

  def template_for(template)
    File.read("resources/templates/#{template}.template.html")
  end

  def resource_for(resource)
    "resources/#{resource}"
  end
end

if __FILE__ == $0
  fname = ARGV[0]
  outputd = ARGV[1]
  pres = Presentation.new fname, outputd
  pres.generate
end
