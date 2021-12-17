# Version 1.2

Feature: Marshal and Unmarshal

    As a Go developer implementing a binary message or file format,
    I want a pair of functions "Marshal/Unmarshal" like those in "encoding/json"
    that convert a struct into a series of bits in a byte slice and vice versa,
    so that I can avoid the complexities of custom bit manipulation.

    Background:
        # Ubiquitous language
        Given a message or file "format"
            """
            A format specifies how bits are arranged to encode information.
            """
        And the format is a series of "bit fields"
            """
            A bit field is one or more adjacent bits representing a value,
            and should not be confused with struct fields.
            """
        And adjacent bit fields are grouped into "words"
            """
            A word is a series of bits that can be simultaneously processed
            by a given computer architecture and programming language.
            """

        # Define format-structs
        And a format is represented by a type definition of a "format-struct"
        And the format-struct nests one or more exported "word-structs"
        And the words are tagged to indicate their lengths in number of bits
            """
            type RFC791InternetHeaderFormatWithoutOptions struct {
                RFC791InternetHeaderFormatWord0 `word:"32"`
                RFC791InternetHeaderFormatWord1 `word:"32"`
                RFC791InternetHeaderFormatWord2 `word:"32"`
                RFC791InternetHeaderFormatWord3 `word:"32"`
                RFC791InternetHeaderFormatWord4 `word:"32"`
            }
            """
        And the length of each word is a multiple of eight in the range [8, 64]

        # Define word-structs
        And each word-struct has exported field(s) corresponding to bit field(s)
        And the fields are of unsigned integer or boolean types
        And the fields are tagged to indicate the lengths of those bit fields
            """
            type RFC791InternetHeaderFormatWord0 struct {
                Version     uint8  `bitfield:"4"`
                IHL         uint8  `bitfield:"4"`
                Precedence  uint8  `bitfield:"3"`
                Delay       bool   `bitfield:"1"`
                Throughput  bool   `bitfield:"1"`
                Reliability bool   `bitfield:"1"`
                Reserved    uint8  `bitfield:"2"`
                TotalLength uint16 `bitfield:"16"`
            }
            """
        And the length of each bit field does not overflow the type of the field
            """
            A bit field overflows a type
            when it is long enough to represent values
            outside the set of values of the type.
            """
        And the sum of lengths of all fields is equal to the length of that word

    Scenario: Marshal a struct into a byte slice
        Given a format-struct variable representing a binary message or file
            """
            internetHeader = RFC791InternetHeaderFormatWithoutOptions{
                RFC791InternetHeaderFormatWord0{
                    Version: 4,
                    IHL:     5,
                    // ...
                },
                // ...
            }
            """
        And the struct field values do not overflow corresponding bit fields
            """
            A struct field value overflows its corresponding bit field
            when it falls outside the range of values
            that can be represented by that bit field given its length.
            """
        When I pass to function Marshal() a pointer to that struct variable
            """
            var (
                bytes []byte
                e     error
            )

            bytes, e = binary.Marshal(&internetHeader)
            """
        Then Marshal() should return a slice of bytes and a nil error
        And I should see struct field values reflected as bits in those bytes
            """
            log.Printf("%08b", bytes)
            // [01000101 ...]

            log.Println(e == nil)
            // true
            """
        And I should see that the lengths of the slice and the format are equal
            """
            The length of a format is the sum of lengths of the words in it.
            The length of a word is the sum of lengths of the bit fields in it.
            """

    Scenario: Unmarshal a byte slice into a struct
        Given a format-struct type representing a binary message or file format
            """
            var internetHeader RFC791InternetHeaderFormatWithoutOptions
            """
        And a slice of bytes containing a binary message or file
            """
            var bytes []byte

            // ...

            log.Printf("%08b", bytes)
            // [01000101 ...]
            """
        And the lengths of the slice and the format (measured in bits) are equal
        When I pass to function Unmarshal() the slice of bytes as an argument
        And I pass to the function a pointer to the struct as a second argument
            """
            e = binary.Unmarshal(bytes, &internetHeader)
            """
        Then Unmarshal() should return a nil error
        And I should see struct field values matching the bits in those bytes
            """
            log.Println(e == nil)
            // true

            log.Println(internetHeader.RFC791InternetHeaderFormatWord0.Version)
            // 4

            log.Println(internetHeader.RFC791InternetHeaderFormatWord0.IHL)
            // 5
            """

    Scenario:
        Given a variable that is not a pointer
        When I pass to <function> as an argument such a variable
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            Argument to <function> should be a pointer to a format-struct.
            Argument to <function> is not a pointer.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a pointer that does not point to a struct variable
        When I pass to <function> such a pointer
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            Argument to <function> should be a pointer to a format-struct.
            Argument to <function> does not point to a struct variable.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a format-struct with no exported fields
        When I pass to <function> a pointer to such a format-struct
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            A format-struct should nest exported word-structs.
            Argument to <function> points to a struct "[StructType]"
            with no exported fields.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given an exported field in a format-struct is not of type struct
        When I pass to <function> a pointer to such a format-struct
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            A format-struct should nest exported word-structs.
            Argument to <function> points to a struct "[StructType]"
            with an exported field "[NameOfStructField]" that is not a struct.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given an exported field in a format-struct with no struct tag
        When I pass to <function> a pointer to such a format-struct
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            Word-structs should be exported fields of a format-struct
            tagged with a key "word" and a value
            indicating the length of the word in number of bits
            (e.g. `word:"32"`).
            Argument to <function> points to a struct "[StructType]"
            with an exported field "[NameOfStructField]" that has no struct tag.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given an exported field in a format-struct with a malformed struct tag
            """
            A struct tag is malformed when its key is not "word"
            or when its value cannot be parsed as an unsigned integer.
            """
        When I pass to <function> a pointer to such a format-struct
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            Word-structs should be exported fields of a format-struct
            tagged with a key "word" and a value
            indicating the length of the word in number of bits
            (e.g. `word:"32"`).
            Argument to <function> points to a struct "[StructType]"
            with an exported field "[NameOfStructField]"
            that has a malformed struct tag.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a word of length not a multiple of eight in the range [8, 64]
        When I pass to <function> a pointer to a format-struct nesting such word
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            The length of a word should be a multiple of eight
            in the range [8, 64].
            Argument to <function> points to a struct "[StructType]"
            nesting a word-struct "[NameOfStructField]" of length [length]
            not in {8, 16, 24, ... 64}.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a word-struct containing no exported fields
        When I pass to <function> a pointer to a format-struct nesting such word
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            A word-struct should have exported fields representing bit fields.
            Argument to <function> points to a struct "[StructType]"
            nesting a word-struct "[NameOfStructField]"
            that has no exported fields.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a word-struct containing a field of unsupported type
            """
            Supported types are uint, uintN where N = {8, 16, 32, 64} and bool.
            """
        When I pass to <function> a pointer to a format-struct nesting such word
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            Exported fields of a word-struct should be of type uintN or bool.
            Argument to <function> points to a struct "[StructType]"
            nesting a word-struct "[NameOfFormatStructField]"
            that has an exported field "[NameOfWordStructField]"
            of unsupported type "[FieldType]".
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a word-struct containing a field with no struct tag
        When I pass to <function> a pointer to a format-struct nesting such word
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            Exported fields in a word-struct should be tagged
            with a key "bitfield" and a value
            indicating the length of the bit field in number of bits
            (e.g. `bitfield:"1"`).
            Argument to <function> points to a struct "[StructType]"
            nesting a word-struct "[NameOfFormatStructField]"
            that has an exported field "[NameOfWordStructField]"
            that has no struct tag.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a word-struct containing a field with a malformed struct tag
            """
            A struct tag is malformed when its key is not "bitfield"
            or when its value cannot be parsed as an unsigned integer.
            """
        When I pass to <function> a pointer to a format-struct nesting such word
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            Exported fields in a word-struct should be tagged
            with a key "bitfield" and a value
            indicating the length of the bit field in number of bits
            (e.g. `bitfield:"1"`).
            Argument to <function> points to a struct "[StructType]"
            nesting a word-struct "[NameOfFormatStructField]"
            that has an exported field "[NameOfWordStructField]"
            that has a malformed struct tag.
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a word-struct containing a field with a v1.1-style struct tag
            """
            type RFC791InternetHeaderFormatWord0 struct {
                Version     uint8  `bitfield:"4,28"`
                IHL         uint8  `bitfield:"4,24"`
                Precedence  uint8  `bitfield:"3,21"`
                Delay       bool   `bitfield:"1,20"`
                Throughput  bool   `bitfield:"1,19"`
                Reliability bool   `bitfield:"1,18"`
                Reserved    uint8  `bitfield:"2,16"`
                TotalLength uint16 `bitfield:"16,0"`
            }
            """
        When I pass to <function> a pointer to a format-struct nesting such word
        Then <function> should return <a byte slice and> a nil error

        Examples:
            | function  | a byte slice and |
            | Marshal   | a byte slice and |
            | Unmarshal |                  |

    Scenario:
        Given a word-struct with a bit field of length overflowing its type
            """
            A bit field overflows a type
            when it is long enough to represent values
            outside the set of values of the type.
            """
        When I pass to <function> a pointer to a format-struct nesting such word
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            The number of unique values a bit field can contain
            must not exceed the size of its type.
            Argument to <function> points to a struct "[StructType]"
            nesting a word-struct "[NameOfFormatStructField]"
            that has a bit field "[NameOfWordStructField]" of length [length]
            exceeding the size of type [FieldType], [size].
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a word of length not equal to the sum of lengths of its bit fields
        When I pass to <function> a pointer to a format-struct nesting such word
        Then <function> should return <a byte slice of zero length and> an error
            """
            <function> error:
            The length of a word
            should be equal to the sum of lengths of its bit fields.
            Argument to <function> points to a struct "[StructType]"
            nesting a word-struct "[NameOfFormatStructField]" of length [length]
            not equal to the sum of the lengths of its bit fields, [sum].
            """

        Examples:
            | function  | a byte slice of zero length and |
            | Marshal   | a byte slice of zero length and |
            | Unmarshal |                                 |

    Scenario:
        Given a format-struct type representing a binary message or file format
        And a slice of bytes containing a binary message or file
        And the lengths of the slice and the format (in bits) are not equal
        When I pass to function Unmarshal() the slice of bytes as an argument
        And I pass to the function a pointer to the struct as a second argument
        Then Unmarshal() should return an error
            """
            Unmarshal error:
            A byte slice into which a format-struct would be unmarshalled
            should have the same length as the format represented by the struct.
            The length of a format is the sum of the lengths of the words in it.
            Argument to Unmarshal() points to a format "[FormatStructType]"
            of length [formatLength] bits
            not equal to length [sliceLength] bits of the byte slice.
            """
