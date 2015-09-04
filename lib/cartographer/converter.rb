require 'oj'

module Cartographer
  class Error < StandardError; end

  class Converter
    LINES = {
      4194424 => "\u2502",
      4194417 => "\u2500",
      4194413 => "\u2514",
      4194412 => "\u250C",
      4194411 => "\u2510",
      4194410 => "\u2518",
      4194420 => "\u251C",
      4194422 => "\u2534",
      4194421 => "\u2524",
      4194423 => "\u252C",
      4194414 => "\u253C",
    }
    ROADS = {
      'north' => "│",
      'south' => "│",
      'west' => "─",
      'east' => "─",
      'nesw' => "┼",
      'ns' => "│",
      'ew' => "─",
      'wn' => "┘",
      'ne' => "└",
      'sw' => "┐",
      'es' => "┌",
      'esw' => "┬",
      'nsw' => "┤",
      'new' => "┴",
      'nes' => "├",
    }
    DIRS = %w{north east south west ns ew sn we}
    HTML_START = """<html><head><style>
body { background: black; color: #aaaaaa; }
.cl_white { color: #ffffff; }
.cl_blue { color: #0000ff; }
.cl_red { color: #ff0000; }
.cl_brown { color: #a52a2a; }
.cl_green { color: #008000; }
.cl_cyan { color: #00ffff; }
.cl_dark_gray { color: #a9a9a9; }
.cl_magenta { color: #ff00ff; }
.cl_yellow { color: #ffff00; }
.cl_light_blue { color: #add8e6; }
.cl_light_green { color: #90ee90; }
.cl_light_red { color: #ff5555; }
.cl_i_ltred { color: black; background: #ff5555; }
.cl_light_gray { color: #d3d3d3; }
.cl_i_ltgray { color: black; background: #d3d3d3; }
.cl_light_cyan { color: #e0ffff; }
.cl_ltgray_yellow { color: #d3d3d3; background: #ffff00; }
.cl_pink { color: #ffc0cb; }
.cl_yellow_magenta { color: #ffff00; background: #ff00ff; }
.cl_white_magenta { color: #ffffff; background: #ff00ff; }
.cl_i_magenta { color: black; background: #ff00ff; }
.cl_pink_magenta { color: #ffc0cb; background: #ff00ff;  }
.cl_i_green { color: black; background: #008000; }
.cl_i_brown { color: black; background: #a52a2a; }
.cl_h_yellow { color: #ffff00; background: #0000ff; }
.cl_h_dkgray { color: #a9a9a9; background: #0000ff; }
.cl_i_ltblue { color: black; background: #add8e6; }
.cl_i_blue { color: black; background: #0000ff; }
.cl_i_red { color: black; background: #ff0000; }
.cl_ltgreen_yellow { color: #d3d3d3; background: #ffff00; }
.cl_white_white { background: white; }
.cl_i_ltcyan { color: black; background: #e0ffff; }
.cl_yellow_cyan { color: #ffff00; background: #00ffff; }
</style><meta content='text/html; charset=utf-8' http-equiv='Content-Type' />
</head><body><pre>"""
    HTML_END = """</pre></body></html>"""

    def initialize(terrain_dat, logger = nil)
      @logger = logger
      @data   = File.open(terrain_dat, 'rb') {|f| Marshal.load(f) }
    end

    def convert(source_path, tgt_file, width: 180, height: 180, layer: 10)
      empty_line = ' ' * width
      maps_raw, stats = get_maps(source_path)
      maps = maps_raw.collect do |row|
        row.collect do |map|
          unless map
            next Array.new(height, empty_line)
          end

          data = get_layer(map, layer)
          strings = Array.new
          line = String.new
          pos = 0

          data.each do |id, len|
            sym, color = get_tile_data(id)
            # does not care about proper Unicode glyphs
            if sym == '<'
              sym = '&#x3c;'
            elsif sym == '>'
              sym = '&#x3e;'
            end
            while len > 0
              line_left = width - pos
              how_many = [line_left, len].min
              if color
                line += "<span class=\"cl_#{color}\">"
              end
              line += sym * how_many
              if color
                line += '</span>'
              end
              pos += how_many
              len -= how_many
              if pos == width
                strings.push(line)
                line = String.new
                pos = 0
              end
            end
          end

          strings
        end.transpose.collect(&:join)
      end

      tgt_file.puts HTML_START
      maps.each {|m| tgt_file.puts m }
      tgt_file.puts HTML_END

      stats
    end

    private

    def get_tile_data(id)
      tile = @data[id]
      if tile
        return [tile[:syms].first, tile[:color]]
      else
        parts = id.split('_')
        suffix = parts.pop
        nid = parts.join('_')

        if nid == 'road'
          sym = ROADS[suffix]
          unless sym
            log :warn, "No road for suffix #{suffix}"
            return ['?', nil]
          end
        else
          tile = @data[nid]
          unless tile
            log :warn, "Tile not found #{id} (#{nid} #{suffix})"
            return ['?', nil]
          end
          dir = DIRS.index(suffix) % 4 rescue 0
          sym = tile[:syms][dir] || tile[:syms].first
          color = tile[:color]
        end
      end
      [sym, color]
    end

    def get_layer(json_path, layer)
      raw = IO.readlines(json_path)
      header = raw.shift

      unless header.match(/# version 25/)
        raise Error, "Unknown header: #{header}"
      end

      Oj::Doc.open(raw.join("\n")) {|d| d.fetch("/layers/#{layer + 1}") }
    end

    def get_maps(dir_path)
      paths = Dir.glob(dir_path + '/o.*')
      if paths.empty?
        raise Error, 'No maps found'
      end

      coords    = Array.new
      seen      = Hash.new
      seen_cnt  = 0
      paths.each do |p|
        x, y = p.match(/o.(-?\d+).(-?\d+)/).captures.map(&:to_i)
        coords.push([x, y])
        seen["#{x} #{y}"] = p
        seen_cnt += 1
      end

      coords = coords.transpose
      min_x, max_x = coords.first.minmax
      min_y, max_y = coords.last.minmax
      width   = -min_x + 1 + max_x
      height  = -min_y + 1 + max_y

      maps = min_y.upto(max_y).collect do |y|
        min_x.upto(max_x).collect do |x|
          seen["#{x} #{y}"]
        end
      end
      size    = width * height
      visited = (seen_cnt.to_f / size.to_f) * 100.0
      stats   = "#{width}x#{height} #{seen_cnt}/#{size} #{visited.round(2)}%"

      [maps, stats]
    end

    def log(level, msg)
      if @logger
        @logger.send(level, msg)
      end
    end
  end
end
