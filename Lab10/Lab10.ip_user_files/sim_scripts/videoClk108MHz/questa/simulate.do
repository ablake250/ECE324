onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib videoClk108MHz_opt

do {wave.do}

view wave
view structure
view signals

do {videoClk108MHz.udo}

run -all

quit -force
