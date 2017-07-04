# NodeMCU-Dual-Pulse-Weld-Timer
Code for NodeMCU based double-pulse battery tab welder

This is the code to go along with the video about the project at https://www.youtube.com/edit?o=U&video_id=5kWRZHLDFLo

Hardware Configuration
* OLED Display attached to SDA->D1,SCL->D2
* Solid State Relay on D8, with NPN transistor to allow 5V switching across SSR
* Microswitch on D4 to trigger weld cycle
* Rotary encoder on CLK->D5, DT->D6, SW->D7 
* NTC Thermistor on A0 for over-temperature detection.

Good Features:
* Actually works correctly.
* Timing functions have been fine-tuned to be accurate
* Supports a 10K NTC attached to pin A0 for over-temperature detection - welding is disabled when too hot

Bad Features:
* I don't know LUA and was too lazy to work it out properly
* Using individual files for each config value because I couldn't get delimiters or string splitting working
* Heavy misuse of if statements because I couldn't be bothered to work out how to use arrays.

