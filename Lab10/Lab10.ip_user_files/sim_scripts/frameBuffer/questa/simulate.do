onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib frameBuffer_opt

do {wave.do}

view wave
view structure
view signals

do {frameBuffer.udo}

run -all

quit -force
