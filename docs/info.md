<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## Glitchable PRESENT-80 Cipher

This project is an implementation of the PRESENT symmetric cipher using a 80-bits encryption key, with a proof-of-concept hardware trojan (as explained [here](https://dr.ntu.edu.sg/server/api/core/bitstreams/d1b476e7-0a8d-4f7d-8717-58f1348b5224/content)).
The trojan allows for inserting distinct glitches on selected nibbles of the output of the S-box at the 30th round, which in turn allow an attacker to recover or brute-force the last round-key.

## How it works

After a reset, four different commands can be issued to the module, using pins `uio_in[1:0]`:

- KEY_IN = 1: read byte from `ui_in` and append it to the inner key register
- DATA_IN = 2: read byte from `ui_in` and append it to the inner data register 
- LOAD = 3: load key and data registers into the crypto module, and start encryption round

When the "data_out_valid" signal (pin `uio_out[2]`) goes high, the ciphertext can be read:

- READ_BYTE = 4: read one byte from inner "data_out" buffer and load it into `uo_out`

**TBC**

## How to test

Limited text at the moment, through the provided Makefile: `make -B`

**TODO**

## ToDos

- automatically insert trojan (glitch) at masks 1,...,4 if the same data is encrypted more than once
- UART ???