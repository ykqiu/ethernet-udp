# Ethernet-UDP  
Github: https://github.com/ykqiu/ethernet-udp  
This project is a gigabit ethernet in Verilog aimed at FPGA or ASIC where requirements for high-speed data collection is needed. For example, in optical communication, video stream or in high-spped ADC signal capture.
This project is mainly done on Xilinx 7 series (Artix, Kintex) using vidado HLS, but it may also be compatible with other platforms or tools in ASIC/FPGA RTL design.
The idea with this project is to capture the incoming data from high-speed host (PC, etc) and store the high band-width data in DDR3, reducing the complexity and hardware requirement. This project consists of the UDP_TX, UDP_RX and a DDR3 controller.
