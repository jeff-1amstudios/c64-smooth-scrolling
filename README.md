# Smooth scrolling screen on Commodore 64

Here is some sample code to implement horizontal smooth scrolling on a C64. 

```
The algorithm in pseudo-code is:

when_graphics_chip_is_at_line_3() {
  if (xscroll == 0) {
    shift_upper_half_of_color_ram();
  }
}

when_graphics_chip_is_at_vblankk() {
   xscroll--;
   if (xscroll == 4) {
      shift_upper_half_of_screen_ram_to_back_buffer();
   }
   else if (xscroll == 2) {
      shift_lower_half_of_screen_ram_to_back_buffer();
   }
   else if (xscroll < 0) {
      swap_screen_buffer();
      shift_lower_half_of_color_ram();
      draw_next_column_to_screen_and_color_ram()
   }
}
```

See http://1amstudios.com/2014-12-07-c64-smooth-scrolling for more details

[DustLayer](http://www.dustlayer.com) is a fanstastic site devoted to C64 internals with great descriptions and tutorials. Highly recommended!
