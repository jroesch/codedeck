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
    style = Pygments.css
    File.write("code.css", style)
    processed_code = code.map do |chunk|
      if chunk.is_a? Array
        Pygments.highlight(chunk.join, :lexer => 'scala')
      else
        Pygments.highlight(chunk.to_s, :lexer => 'scala')
      end
    end
    processed_code
  end
end

class Presentation 
  def generate
    hl = Highlighter.new("#{Dir.pwd}/Deck.scala")
    slide_template = File.read("#{Dir.pwd}/slide.template.html")
    presentation_template = File.read("#{Dir.pwd}/presentation.template.html")
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
end

p = Presentation.new
p.generate
