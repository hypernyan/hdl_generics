# hdl_generics
Generic HDL components to be used in different projects
## bin2bcd
Binary coded decimal to binary and vice versa converter. 
Start conversion by asserting `conv` for 1 tick
## debouncer
Debounce signals from mechanical input devices (buttons, encoders, switches, etc)
## encoder
Processes input from quadrature encoders. Generates clockwise and counterclockwise signals
### dependencies
- debouncer.sv
## fifo
Single- and dual clock FIFOs. Two versions for each with or without `interface`
### dependencies
- ram.sv
## i2c
I2C master with read and write functions
## int_divider
Iterative integer divider
## mem_arb
Allows multiple RAM access without collision. Buffers requests for write and read and replies with read result
## nco
Quadrature LUT-based NCO
## onehot
Convert a vector with multiple bits set to a vector with only one bit set (MSB or LSB)
## ram
Single- and dual port RAM
## sum
Recursive summation module
## mult
Shift-add multiplier
## stretch
Stretches a pulse by specified amount. Delay is constant in respect to pulse centers