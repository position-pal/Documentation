require 'find'
require 'fileutils'

def plantuml_installed?
  system("command -v plantuml > /dev/null 2>&1")
end

unless plantuml_installed?
  puts "PlantUML is not installed. Please install it first."
  exit 1
end

if ARGV.length != 2 || !File.directory?(ARGV[0]) || !File.directory?(ARGV[1])
  output = <<~EOF
    A script to embed PlantUML diagrams in markdown files.

    Usage: plant-in-md.rb <root_directory> <output_directory>
  
    Arguments:
      <root_directory> - The root directory where the markdown files are located
      <output_directory> - The directory where the generated SVG diagrams are saved

    The script searches for PlantUML code blocks in mardkdown files (starting from 
    the <root_directory> and walking top-down recursively), generates the SVG 
    diagrams (in the <output_directory>) and embeds them in the markdown files as images. 
    To make sure the diagrams are displayed correctly (especially for large diagrams), 
    the script wraps the images in a scrollable container.
  EOF
  puts output
  exit 1
end

def move_diagrams_to(path, output_dir, suffix = "light")
  Dir.glob(File.join(File.dirname(path), "*.svg")).each do |file|
    file_name = File.basename(file, ".svg")
    destination = File.join(output_dir, "#{file_name}-#{suffix}.svg")
    FileUtils.mv(file, destination)
  end
end

def generate_svg_diagrams(path, output_dir)
  puts "Generating SVG diagrams for #{path} in #{output_dir}..."
  system("plantuml -tsvg #{path}")
  move_diagrams_to(path, output_dir)
  system("plantuml -tsvg -darkmode #{path}")
  move_diagrams_to(path, output_dir, "dark")
end

def update_md(path, output_dir)
  content = File.read(path)
  updated_content = content.gsub(/```plantuml\s*\n\s*(@start[\w-]+)\s+([\w-]+)\n(.*?)\n```/m) do
    diagram_name = $2
    puts File.join(output_dir, diagram_name)
    <<~EOF
    <div style="width: 100%; overflow-x: auto; white-space: nowrap;">
      <img 
        src="/#{File.join(output_dir, diagram_name)}.svg" 
        alt="#{diagram_name} schema" 
        style="max-width: none;"
        class="schema"
      />
    </div>
    EOF
  end
  File.write(path, updated_content)
end

def add_js_utilities(path)
  content = File.read(path)
  head_index = content.index("<head>")
  code = <<~EOF
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script>
      function updateDiagramImage() {
        const darkMode = $('html').attr('data-dark-mode') !== undefined;
        const suffix = darkMode ? '-dark' : '-light';
        $('.schema').each(function() {
          const imgElement = $(this);
          const originalSrc = imgElement.attr('src');
          imgElement.attr('src', originalSrc + suffix + '.svg');
        });
      }
      $(document).on('DOMSubtreeModified', 'html', updateDiagramImage);
      $(document).ready(updateDiagramImage);
    </script>
  EOF
  if head_index
  File.write(path, updated_content)
end

MARKDOWN_FILE_EXTENSION = ".md"

def process_md_files(directory, output_dir)
  Find.find(directory) do |path|
    if File.file?(path) && File.extname(path) == MARKDOWN_FILE_EXTENSION
      generate_svg_diagrams(path, output_dir)
      add_js_utilities(path)
      update_md(path, output_dir)
    end
  end
end

root_directory = ARGV[0]
output_directory = ARGV[1]
puts "Processing markdown files in #{root_directory}..."
process_md_files(root_directory, output_directory)
puts "Done."
