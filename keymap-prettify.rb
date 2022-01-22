# coding: utf-8

keymap_file_loc = ARGV[0]

# rows and col nums per half of keyboard
@row_nums = 3
@col_nums = 5

# number of keys on left and right thumb cluster
@left_thumb_cluster = 3
@right_thumb_cluster = 2

def longest_keycode_len(layer)
  max = 0
  longest_keycode = ""
  layer.each do |row|
    row.each do |keycode|
      if keycode.length > max
        max = keycode.length
        longest_keycode = keycode
      end
    end
  end

  return max
end

def pretty_borders(longest_keycode_len, border_type)
  connecting_border = "─" * (@col_nums * (longest_keycode_len + 1))
  left_conn_border_thumb = "─" * (@left_thumb_cluster * (longest_keycode_len + 1))
  right_conn_border_thumb = "─" * (@right_thumb_cluster * (longest_keycode_len + 1))

  tab_spacing = " " * longest_keycode_len

  border_types = {
    "beg" => "╭#{connecting_border}╮#{tab_spacing}╭#{connecting_border}╮",
    "mid" => "├#{connecting_border}┤#{tab_spacing}├#{connecting_border}┤",
    "end_reg" => "╰#{connecting_border}┤#{tab_spacing}├#{connecting_border}╯",
    "end_thumb" => "╰#{left_conn_border_thumb}╯#{tab_spacing}╰#{right_conn_border_thumb}╯",
  }

  return border_types[border_type]
end

def generate_pretty_table(layer)
  longest_keycode_len = longest_keycode_len(layer)

  puts "// " + pretty_borders(longest_keycode_len, "beg")

  # The last row is typically contains keys for the thumbclusters
  is_last_row = false
  thumbcluster_spacing = ""

  layer.each_with_index do |row, r_idx|
    prettified_row = ""

    if r_idx == layer.length - 1
      is_last_row = true
    end

    # Iterate through keycodes in row
    row.each_with_index do |keycode, c_idx|
      spacing = " "
      # tab spacing is used to separate keys on left side of split keyboard, and
      # right side of split keyboard
      tab_spacing = ""
      left_thumb_spacing = ""
      right_thumb_spacing = ""

      # + 1 to account for space after comma in between keycodes
      if keycode.length < longest_keycode_len + 1
        spacing = spacing * (longest_keycode_len - keycode.length)
      end

      if c_idx + 1 == @col_nums or (is_last_row and (c_idx + 1) == @left_thumb_cluster)
        # +2 for the separators in between borders e.g. space between these two
        # separators ╮ ╭
        tab_spacing = " " * (longest_keycode_len + 2)
      elsif is_last_row and c_idx == 0
        # The +1 is to account for the comma after each keycode
        thumbcluster_spacing = " " * ((longest_keycode_len + 1) * (@col_nums - @left_thumb_cluster))
        prettified_row += thumbcluster_spacing
      end

      # include comma after each keycode except for last keycode
      if !(c_idx + 1 == @col_nums and is_last_row)
        spacing += ","
      end

      prettified_row += "#{keycode}#{spacing}#{tab_spacing}"
    end

    if is_last_row == true
      puts "// " + pretty_borders(longest_keycode_len, "end_reg")
    elsif r_idx > 0
      puts "// " + pretty_borders(longest_keycode_len, "mid")
    end

    puts "    " + prettified_row
  end

  puts "// " + thumbcluster_spacing + pretty_borders(longest_keycode_len, "end_thumb")
end

if keymap_file_loc == nil
  puts "pass in keymap file location as argument usage: (ruby keymap-prettify.rb path-to-keymap.c)"
else
  layer_start = false

  keymaps_arr = Array.new
  layer = Array.new

  File.foreach(keymap_file_loc) do |line|
    # If a line includes the LAYOUT macro, the next lines until ')' or '),' will
    # specify the layout of the keyboard
    if layer_start == false and line.include? "LAYOUT"

      # beginning of layer because current line includes LAYOUT, append new line
      # before printing line that contains LAYOUT macro
      puts
      # remove leading and trailing spaces from line
      puts line.strip

      layer_start = true
      layer = Array.new
    elsif layer_start == true
      # If the line doesn't contain LAYOUT macro definiton, remove all white
      # space and all characters except: letters, numbers, commas, (), and _
      stripped_line = line.gsub(/[^a-zA-Z0-9)(,_]/, "")

      if stripped_line.eql? ")" or stripped_line.eql? "),"
        # end of layer
        layer_start = false
        keymaps_arr.push(layer)

        generate_pretty_table(layer)
        # Print line that contains ')' this is to close the layer definition
        puts line
      else
        # line currently is neither the beginning of LAYOUT macro or end of layout macro
        paren_open = false

        keycode_arr = Array.new
        keycode = ""

        stripped_line.each_char.with_index do |char, idx|
          if char.eql? "("
            paren_open = true
          elsif char.eql? ")"
            paren_open = false
          elsif paren_open == false and char == ","
            paren_open = false
            keycode_arr.push(keycode)
            keycode = ""
          end

          # we want to add commas that are in between parenthesis
          if paren_open == true or char != ","
            keycode = keycode + char
          end

          if idx == stripped_line.length - 1 and keycode.length > 0
            keycode_arr.push(keycode)
            keycode = ""
          end
        end

        # puts stripped_line

        if keycode_arr.size > 0
          layer.push(keycode_arr)
        end
      end
    end
  end
end
