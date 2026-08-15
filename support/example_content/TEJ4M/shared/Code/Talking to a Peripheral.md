---
title: Talking to a Peripheral
publish: true
created: __CREATED__
tags:
  - code
enableToc: true
---
The sensor in [[Talk on a Bus]] arrives as a small board with four pins
and a twenty-page datasheet, and it will not tell you anything until you
ask in exactly the form it expects. This page is that conversation:
finding the device, reading one of its registers, and turning the bytes
that come back into a number you can defend.

## The wiring and the datasheet come first

Before a line of code, four facts have to be written in your build log,
all of them from the datasheet rather than from a forum post.

1. **Supply voltage and logic level.** A 5 V device on a 3.3 V bus needs
   translation, not hope.
2. **The bus and its wiring.** I²C needs pull-ups on both lines and the
   right value for your bus capacitance; SPI needs a chip select per
   device. [[Communication Buses]] is the argument behind both.
3. **The device address** — and how it changes if an address pin is tied
   high or low, which is how you get two identical sensors on one bus.
4. **The register map**: which register holds what, its width, whether
   the value is signed, and the byte order.

## Finding the device on the bus

```python
# scan.py — run this once, before writing any driver code.
from machine import I2C, Pin

# Pin numbers are examples. Check your own board's pinout.
i2c = I2C(0, scl=Pin(5), sda=Pin(4), freq=100000)

found = i2c.scan()
print("devices found:", len(found))
for address in found:
    print("  address", hex(address))
```

An empty list is information, not a failure: it means the bus is not
working at all, and no amount of driver code will help. Check the
pull-ups, the wiring, the supply, and whether the device you bought uses
the address you assumed. A list with the wrong address on it is equally
useful — it usually means an address pin is strapped the other way.

Start at 100 kHz. Get it working slowly, then raise the speed and confirm
it still works; if it stops working at 400 kHz you have learned something
real about your wiring rather than about your code.

## Reading a register

Nearly every peripheral works the same way: you write the number of the
register you want, then read bytes back from it. MicroPython gives you
both the explicit form and a convenience form.

```python
# driver.py — a small temperature sensor, as an example shape.
from machine import I2C, Pin
import struct

SENSOR_ADDRESS = 0x48        # confirm against your part and its address pins
REG_TEMPERATURE = 0x00       # from the register map
REG_CONFIG = 0x01

i2c = I2C(0, scl=Pin(5), sda=Pin(4), freq=100000)


def read_register(register, length):
    """Return `length` raw bytes from `register`."""
    return i2c.readfrom_mem(SENSOR_ADDRESS, register, length)


def write_register(register, value):
    """Write one byte to `register`."""
    i2c.writeto_mem(SENSOR_ADDRESS, register, bytes([value]))
```

`readfrom_mem` performs the whole exchange — write the register number,
repeated start, read the data — in one call. If your device needs a
sequence the convenience call does not fit, `i2c.writeto` followed by
`i2c.readfrom` gives you the pieces, at the cost of having to get the
start and stop conditions right yourself.

The same shape in SPI looks like this, and the differences are exactly
the ones [[Communication Buses]] predicted — a chip select you control,
and no address in the frame:

```python
from machine import SPI, Pin

spi = SPI(0, baudrate=1000000, polarity=0, phase=0)
chip_select = Pin(17, Pin.OUT, value=1)     # idle high


def spi_read_register(register, length):
    chip_select.value(0)
    spi.write(bytes([register | 0x80]))     # many parts set bit 7 to read
    data = spi.read(length)
    chip_select.value(1)
    return data
```

The `| 0x80` is not a universal truth — it is what one particular family
of parts uses to mean "this is a read". Your datasheet says what yours
uses. Copying that line without checking is the single most common way a
working SPI driver becomes a silent one.

## Turning raw bytes into a number

Bytes are not values. A 16-bit reading arrives as two bytes, and three
separate facts decide what number they represent: the byte order, whether
the value is signed, and the scale factor the datasheet gives.

```python
def read_celsius():
    """Return the temperature in degrees Celsius.

    The part returns 16 bits, most significant byte first, in two's
    complement, with one count equal to 0.01 degrees Celsius.
    """
    data = read_register(REG_TEMPERATURE, 2)
    counts = struct.unpack(">h", data)[0]    # > big-endian, h signed 16-bit
    return counts * 0.01
```

`struct.unpack` does the work, but you must be able to do it by hand,
because the day the format is unusual you will have to. Two's complement
says that in a 16-bit field, any value from 0x8000 upward represents a
negative number, found by subtracting 0x10000:

```python
def to_signed_16(unsigned_value):
    """Interpret a 16-bit unsigned value as two's complement."""
    if unsigned_value >= 0x8000:
        return unsigned_value - 0x10000
    return unsigned_value
```

Work two examples on paper and check them against the code. The bytes
`0x0C 0x80` make `0x0C80`, which is $12 \times 256 + 128 = 3200$ counts,
and at 0.01 °C per count that is **32.00 °C**. The bytes `0xFF 0x38` make
`0xFF38`, which is 65 336 — above 0x8000, so it is negative, and
$65\,336 - 65\,536 = -200$ counts, or **−2.00 °C**. Read those same bytes
as unsigned and you would report
653.36 °C — a number no plausibility check should ever let out of the
building, which is the point of [[Defensive Embedded Code]].

Byte order catches the other half of the class. Swap the two bytes above
and `0x80 0x0C` is 32780 unsigned, or −32756 signed: a wildly different
answer from the same bits. If your readings are absurd but change when
the sensor changes, suspect the byte order before you suspect the sensor.

## When the device does not answer

Work in this order, and record what each step showed:

1. **Scan the bus.** No device means wiring, pull-ups, address, or power.
2. **Read a register whose value you already know** — most parts have an
   identification register with a fixed value. If that reads correctly,
   the conversation works and the problem is in your interpretation.
3. **Look at the wires.** A logic analyzer shows the address on the bus,
   the acknowledgement bit, and whether the clock is what you asked for.
   [[Using a Logic Analyzer]] pays for itself in one afternoon.
4. **Slow the bus down** to 100 kHz and shorten the wires.
5. **Check the timing the datasheet requires.** Many parts need a
   conversion time between the command and a valid reading; asking too
   early returns the previous value, or zero, entirely without complaint.

Wrap the bus calls so a failure is visible rather than fatal, because a
sensor that stops answering must not take the whole device down with it:

```python
def try_read_celsius():
    """Return a temperature, or None if the device did not answer."""
    try:
        return read_celsius()
    except OSError as error:
        print("sensor read failed:", error)
        return None
```

A caller that receives `None` can hold its last good value, enter a fault
state, or shut the output down — decisions your specification should
already have made. Bring the working driver, the register map notes, and
the logic-analyzer capture to [[The Interface]]; the capture is the
evidence that the bus is doing what you say it is, and
[[Bus and Protocol Practice]] is where the timing arithmetic behind it
gets drilled.

%%curriculum-start%%
## Curriculum connection

![[A2.4]]

![[A5.1]]

![[B5.3]]
%%curriculum-end%%
