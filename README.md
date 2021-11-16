# Encode and Decode Binary Formats in Go
This module wraps the package `encoding/binary` of the Go standard library and
provides the missing `Marshal()` and `Unmarshal()` functions
a la `encoding/json` and `encoding/xml`.

## Binary Message and File Formats
Messsage and file formats speecify how bits are arranged to encode information.
Control over individual bits or groups of smaller than a byte is often required
to put together and take apart these binary structures.

### Message Formats
Example taken from [RFC 791](https://datatracker.ietf.org/doc/html/rfc791#section-3.1)
defining the Internet Protocol:

```
    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |Version|  IHL  |Type of Service|          Total Length         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |         Identification        |Flags|      Fragment Offset    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  Time to Live |    Protocol   |         Header Checksum       |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                       Source Address                          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Destination Address                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Options                    |    Padding    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

                    Example Internet Datagram Header

                               Figure 4.

  Note that each tick mark represents one bit position.

  ...

  Type of Service:  8 bits

    ...

      Bits 0-2:  Precedence.
      Bit    3:  0 = Normal Delay,      1 = Low Delay.
      Bits   4:  0 = Normal Throughput, 1 = High Throughput.
      Bits   5:  0 = Normal Relibility, 1 = High Relibility.
      Bit  6-7:  Reserved for Future Use.

         0     1     2     3     4     5     6     7
      +-----+-----+-----+-----+-----+-----+-----+-----+
      |                 |     |     |     |     |     |
      |   PRECEDENCE    |  D  |  T  |  R  |  0  |  0  |
      |                 |     |     |     |     |     |
      +-----+-----+-----+-----+-----+-----+-----+-----+

        Precedence

          111 - Network Control
          110 - Internetwork Control
          101 - CRITIC/ECP
          100 - Flash Override
          011 - Flash
          010 - Immediate
          001 - Priority
          000 - Routine
```

Note how the Internet Datagram Header is visualised as a series
of six 32-bit "words".

### File Formats
Example taken from [RFC 1952](https://datatracker.ietf.org/doc/html/rfc1952#page-5)
defining the GZIP file format:

```
   1.2. Intended audience

      ...

      The text of the specification assumes a basic background in
      programming at the level of bits and other primitive data
      representations.

   2.1. Overall conventions

      In the diagrams below, a box like this:

         +---+
         |   | <-- the vertical bars might be missing
         +---+

      represents one byte; ...

   2.2. File format

      A gzip file consists of a series of "members" (compressed data
      sets).  The format of each member is specified in the following
      section.  The members simply appear one after another in the file,
      with no additional information before, between, or after them.

   2.3. Member format

      Each member has the following structure:

         +---+---+---+---+---+---+---+---+---+---+
         |ID1|ID2|CM |FLG|     MTIME     |XFL|OS | (more-->)
         +---+---+---+---+---+---+---+---+---+---+

      ...

      2.3.1. Member header and trailer

         ...

         FLG (FLaGs)
            This flag byte is divided into individual bits as follows:

               bit 0   FTEXT
               bit 1   FHCRC
               bit 2   FEXTRA
               bit 3   FNAME
               bit 4   FCOMMENT
               bit 5   reserved
               bit 6   reserved
               bit 7   reserved
```

## Working with Binary Formats in Go
The smallest data structure Go provides is the basic type `byte` (= `int8`).
Bitwise logical and shift operators are however available.

### Relevant Questions Posted on StackOverflow
Suggestions on StackOverflow in response to the above-described need
are limited to the use of bitwise operators.

* [Golang: Parse bit values from a byte](https://stackoverflow.com/questions/54809254/golang-parse-bit-values-from-a-byte)
* [Creating 8 bit binary data from 4,3, and 1 bit data in Golang](https://stackoverflow.com/questions/61885659/creating-8-bit-binary-data-from-4-3-and-1-bit-data-in-golang)

## An Elegant Solution
Encoding and decoding binary formats in Go should be a matter of
attaching tags to struct fields and calling `Marshal()`/`Unmarshal()`.

```go
package main

import (
	"log"

	"github.com/joel-ling/go-bitfields/pkg/encoding/binary"
)

type rfc791InternetHeaderWord0 struct {
	// Reference: RFC 791 Internet Protocol, Section 3.1 Internet Header Format
	// https://datatracker.ietf.org/doc/html/rfc791#section-3.1

	Version                  uint                           `bitfield:"4,28"`
	InternetHeaderLength     uint                           `bitfield:"4,24"`
	TypeOfServicePrecedence  rfc791InternetHeaderPrecedence `bitfield:"3,21"`
	TypeOfServiceDelay       bool                           `bitfield:"1,20"`
	TypeOfServiceThroughput  bool                           `bitfield:"1,19"`
	TypeOfServiceReliability bool                           `bitfield:"1,18"`
	TypeOfServiceReserved    uint                           `bitfield:"2,16"`
	TotalLength              uint                           `bitfield:"16,0"`
}

type rfc791InternetHeaderPrecedence byte

const (
	rfc791InternetHeaderPrecedenceRoutine rfc791InternetHeaderPrecedence = iota
	rfc791InternetHeaderPrecedencePriority
	rfc791InternetHeaderPrecedenceImmediate
	rfc791InternetHeaderPrecedenceFlash
	rfc791InternetHeaderPrecedenceFlashOverride
	rfc791InternetHeaderPrecedenceCRITICOrECP
	rfc791InternetHeaderPrecedenceInternetworkControl
	rfc791InternetHeaderPrecedenceNetworkControl
)

func main() {
	const (
		internetHeaderLength  = 5
		internetHeaderVersion = 4

		internetHeaderDelayNormal = false
		internetHeaderDelayLow    = true

		internetHeaderThroughputNormal = false
		internetHeaderThroughputHigh   = true

		internetHeaderReliabilityNormal = false
		internetHeaderReliabilityHigh   = true

		internetHeaderTotalLength = 30222

		reserved = 0
	)

	const (
		formatBytes  = "%08b"
		formatStruct = "%#v"
	)

	var (
		structure0 = rfc791InternetHeaderWord0{
			Version:                  internetHeaderVersion,
			InternetHeaderLength:     internetHeaderLength,
			TypeOfServicePrecedence:  rfc791InternetHeaderPrecedenceImmediate,
			TypeOfServiceDelay:       internetHeaderDelayLow,
			TypeOfServiceThroughput:  internetHeaderThroughputNormal,
			TypeOfServiceReliability: internetHeaderReliabilityHigh,
			TypeOfServiceReserved:    reserved,
			TotalLength:              internetHeaderTotalLength,
		}

		structure1 = rfc791InternetHeaderWord0{}
	)

	var (
		bytes []byte
		e     error
	)

	bytes, e = binary.Marshal(&structure0)
	if e != nil {
		log.Fatalln(e)
	}

	log.Printf(formatBytes, bytes)
	// [01000101 01010100 01110110 00001110]

	e = binary.Unmarshal(bytes, &structure1)
	if e != nil {
		log.Fatalln(e)
	}

	log.Printf(formatStruct, structure1 == structure0)
	// true
}
```

Large structures can be encoded and decoded in 32-bit instalments.

### Struct Tags
The encoding of every struct field is determined by a struct tag
of the following key and format:

`bitfield:"<length>,<offset>"`

#### Length
`<length>` refers to an integer representing the bit-length of a field, i.e.
the number of bits in the field.

#### Offset
`<offset>` refers to an integer
representing the number of places the bit field should be shifted left
from the rightmost section of a 32-bit sequence
for its position in that sequence to be appropriate.
It is also the number of places to the right of the rightmost bit of the field.
