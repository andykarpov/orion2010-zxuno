
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name Orion2010 -dir "/home/andy/Documents/Projects/Retrocomp/FPGA/ZXUNO/orion-2010-zxuno/ise/planAhead_run_1" -part xc6slx9tqg144-2
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "/home/andy/Documents/Projects/Retrocomp/FPGA/ZXUNO/orion-2010-zxuno/src/pins.ucf" [current_fileset -constrset]
add_files [list {../src/cores/font/font.ngc}]
set hdlfile [add_files [list {../src/cores/pll/pll.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/T80/T80_Reg.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/T80/T80_Pack.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/T80/T80_MCode.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/T80/T80_ALU.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/T80/T80.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/keyboard/ps2_keyboard.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/T80/T80s.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/keyboard/orionkeyboard.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/cores/font/font.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/async_transmitter.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/async_receiver.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/vga_test.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/orion2010.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top orion2010 $srcset
add_files [list {/home/andy/Documents/Projects/Retrocomp/FPGA/ZXUNO/orion-2010-zxuno/src/pins.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {../src/cores/font/font.ncf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx9tqg144-2
