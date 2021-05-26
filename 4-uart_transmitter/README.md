<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/ayengec/FPGA-Design-with-Systemverilog">
    <img src="https://developer.electricimp.com/sites/default/files/attachments/images/uart/uart3.png" alt="Logo" width="175" height="90">
  </a>

  <h3 align="center">UART TRANSMITTER DESIGN WITH SYSTEMVERILOG</h3>

  <p align="center">
    UART_TX
    <br />
    <a href="https://github.com/ayengec/FPGA-Design-with-Systemverilog/issues">Report Bug</a>
    ·
    <a href="https://github.com/ayengec/FPGA-Design-with-Systemverilog/issues">Request Feature</a>
  </p>
</p>

<!-- ABOUT THE PROJECT -->
## Project Summary
![image](https://github.com/ayengec/FPGA-Design-with-Systemverilog/blob/main/uart_transmitter/docs/tx_hierarchy.PNG)


### Built With
This section should list any major frameworks that you built your project using. Leave any add-ons/plugins for the acknowledgements section. Here are a few examples.
* [Vivado](https://www.xilinx.com/products/design-tools/vivado.html)
* [Basys 3](https://store.digilentinc.com/basys-3-artix-7-fpga-beginner-board-recommended-for-introductory-users/)
* [VSCode](https://code.visualstudio.com)
* [Salae](https://www.saleae.com/downloads/)

<!-- GETTING STARTED -->
## State Diagram of UART Transmitter
![image](https://github.com/ayengec/FPGA-Design-with-Systemverilog/blob/main/uart_transmitter/docs/FSM_transmitter.jpg)

### To clone project
Clone the repo
   ```sh
   git clone https://github.com/ayengec/FPGA-Design-with-Systemverilog.git
   ```
<!-- ABOUT THE PROJECT -->
## RTL Schematic
![image](https://github.com/ayengec/FPGA-Design-with-Systemverilog/blob/main/uart_transmitter/docs/RTL_sch_transmitter.PNG)

## Simulation Result When Data=0x7A
![image](https://github.com/ayengec/FPGA-Design-with-Systemverilog/blob/main/uart_transmitter/docs/only_tx_sim_wave_7a.PNG)

## Simulation Result When Data=0xB6
![image](https://github.com/ayengec/FPGA-Design-with-Systemverilog/blob/main/uart_transmitter/docs/only_tx_sim_wave_b6.PNG)

<!-- USAGE EXAMPLES -->
## Video
You can click below to see how it works on real FPGA board then monitoring on PC with logic analyzer.
<br />
[![BASYS 3 - UART Trasmitter monitoring with logic analyzer](https://img.youtube.com/vi/_bHM_PXv9wk/0.jpg)](https://www.youtube.com/watch?v=_bHM_PXv9wk "BASYS 3 - UART Trasmitter monitoring with logic analyzer")

