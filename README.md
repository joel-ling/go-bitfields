# Encode and Decode Binary Formats in Go
This module wraps the package
[`encoding/binary`](https://pkg.go.dev/encoding/binary)
of the Go standard library and
provides the missing `Marshal()` and `Unmarshal()` functions
a la `encoding/json` and `encoding/xml`.

## Intended Audience
This module is useful to developers
implementing binary message and file format specifications
using the Go programming language.
Whereas stable implementations of most open-source formats
are readily available,
proprietary formats often require bespoke solutions.
The Go standard library provides convenient functions
`Marshal()` and `Unmarshal()`
for converting Go structs into text-based data formats
(such as [JSON](https://pkg.go.dev/encoding/json#Marshal) and
[XML](https://pkg.go.dev/encoding/xml#Marshal))
and vice versa,
but their counterparts for binary formats
are sorely missing from the package `encoding/binary`.

## Binary Message and File Formats
Message and file formats specify how bits are arranged to encode information.
Control over individual bits or groups smaller than a byte is often required
to put together and take apart these binary structures.

### Message Formats
Messages are the lifeblood of network applications.
The following specifications describe the anatomy of TCP/IP headers
at the beginning of every internet datagram (more fondly known as a "packet").
It is highly unlikely that a developer
would ever need to implement these protocols
(since in Go, the package [`net`](https://pkg.go.dev/net)
supplies types and methods that abstract away low-level details),
but they make appropriate illustrations of binary message formats.

#### RFC 791 Internet Protocol
##### Section [3.1](https://datatracker.ietf.org/doc/html/rfc791#section-3.1) Internet Header Format
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
      Bit    3:  0 = Normal Delay,       1 = Low Delay.
      Bits   4:  0 = Normal Throughput,  1 = High Throughput.
      Bits   5:  0 = Normal Reliability, 1 = High Reliability.
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

Notice how the Internet Datagram Header is visualised as a series
of five or more 32-bit "words".
The number of bits found in a word is an artifact of CPU architecture and
is closely related to the number of bits
that can be processed by the arithmetic logic unit of a CPU
in a single operation.

#### RFC 793 Transmission Control Protocol
##### Section [3.1](https://datatracker.ietf.org/doc/html/rfc793#section-3.1) Header Format
```
    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |          Source Port          |       Destination Port        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                        Sequence Number                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Acknowledgment Number                      |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  Data |           |U|A|P|R|S|F|                               |
   | Offset| Reserved  |R|C|S|S|Y|I|            Window             |
   |       |           |G|K|H|T|N|N|                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |           Checksum            |         Urgent Pointer        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Options                    |    Padding    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                             data                              |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

                            TCP Header Format

          Note that one tick mark represents one bit position.

                               Figure 3.
```

### File Formats
Binary file formats are not significantly different from message formats
from an application developer's perspective,
since the operating system and programming language abstract both types
as a sequence of bytes.

#### [RFC 1952](https://datatracker.ietf.org/doc/html/rfc1952) GZIP File Format Specification
##### Various sections

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

Package [`compress/gzip`](https://pkg.go.dev/compress/gzip)
in the Go standard library spares developers the need to (de)serialise
or even to understand the GZIP file format,
but the example is included here as a stand-in for other, custom formats.

## Working with Binary Formats in Go
The smallest data structures Go provides are
the basic type `byte` (alias of `uint8`, an unsigned 8-bit integer), and `bool`,
both eight bits long.
To manipulate data at a scale smaller than eight bits
would require the use of bitwise logical and shift [operators](https://go.dev/ref/spec#Arithmetic_operators) such as
[AND](https://en.wikipedia.org/wiki/Bitwise_operation#AND) (`&`),
[OR](https://en.wikipedia.org/wiki/Bitwise_operation#OR) (`|`),
left [shift](https://en.wikipedia.org/wiki/Bitwise_operation#Bit_shifts) (`<<`),
and right shift (`>>`).

### Relevant Questions Posted on StackOverflow
Suggestions on StackOverflow in response to the above-described need
are limited to the use of bitwise operators.

* [Golang: Parse bit values from a byte](https://stackoverflow.com/questions/54809254/golang-parse-bit-values-from-a-byte)
* [Creating 8 bit binary data from 4,3, and 1 bit data in Golang](https://stackoverflow.com/questions/61885659/creating-8-bit-binary-data-from-4-3-and-1-bit-data-in-golang)

### Using This Module
Encoding and decoding binary formats in Go should be a matter of
attaching tags to struct fields and calling `Marshal()`/`Unmarshal()`,
in the same fashion as JSON (un)marshalling familiar to many Go developers.
This module is meant to be imported in lieu of `encoding/binary`.
Exported variables, types and functions of the standard library package
pass through and are available as though that package had been imported.

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
There are plans to support words of variable length up to 64 bits
(the longest data types that support bitwise operators in Go are 64-bits long),
but only 32-bit words are available in the meantime.

```go
type rfc791InternetHeader struct {
	rfc791InternetHeaderWord0
	rfc791InternetHeaderWord1
	rfc791InternetHeaderWord2
	rfc791InternetHeaderWord3
	rfc791InternetHeaderWord4
}

const (
	bytesPerWord = 4
)

var (
	bytes               []byte
	internetHeader      rfc791InternetHeader
	internetHeaderBytes []byte

	e error
	i int

	internetHeaderWords = []interface{}{
		&internetHeader.rfc791InternetHeaderWord0,
		&internetHeader.rfc791InternetHeaderWord1,
		&internetHeader.rfc791InternetHeaderWord2,
		&internetHeader.rfc791InternetHeaderWord3,
		&internetHeader.rfc791InternetHeaderWord4,
	}
)

for i = 0; i < len(internetHeaderWords); i++ {
	bytes, e = binary.Marshal(internetHeaderWords[i])
	if e != nil {
		// ...
	}

	copy(internetHeaderBytes[bytesPerWord*i:], bytes)
}
```

### Struct Tags
The encoding of every struct field is determined by a compulsory struct tag
of the following key and format:

`bitfield:"<length>,<offset>"`

Unused or "reserved" fields should nonetheless by defined and tagged
even though they contain all zeroes.

#### Length
`<length>` is an integer representing the bit-length of a field, i.e.
the number of bits in the field.

#### Offset
`<offset>` is an integer
representing the number of places the bit field should be shifted left
from the rightmost section of a 32-bit sequence
for its position in that sequence to be appropriate.
It is also the number of places to the right of the rightmost bit of the field.

In a fully utilised 32-bit word,
the offset of every field is the cumulative sum of their lengths,
starting from the rightmost field.
