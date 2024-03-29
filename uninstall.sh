#!/bin/bash

# Install this Ipelet in a linux environment
# tested on:
#	- Ubuntu (2021/07/23)

# common files
rm -f ~/.ipe/ipelets/ev_auxiliary_functions.lua
rm -f ~/.ipe/ipelets/ev_make_dialog.lua
rm -f ~/.ipe/ipelets/ev_parse_input_data.lua
rm -f ~/.ipe/ipelets/ev_queue.lua

rm -f ~/.ipe/ipelets/lev_draw_input_data.lua
rm -f ~/.ipe/ipelets/cev_draw_input_data.lua

rm -f ~/.ipe/ipelets/ev_embedding_visualizer.lua

# remove the old lua files
rm -f ~/.ipe/ipelets/lev_draw_input_data.lua
rm -f ~/.ipe/ipelets/lev_embedding_visualizer.lua
rm -f ~/.ipe/ipelets/cev_draw_input_data.lua
rm -f ~/.ipe/ipelets/cev_embedding_visualizer.lua
