package validation

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestWordWithMalformedTagError(t *testing.T) {
	const (
		formatName   = "Format"
		functionName = "Marshal"
		wordName     = "Word"

		errorMessage = "" +
			"A format-struct should nest exported word-structs " +
			"tagged with a key \"word\" and a value " +
			"indicating the length of a word in number of bits " +
			"(e.g. `word:\"32\"`). " +
			"Argument to Marshal points to a format-struct \"Format\" " +
			"nesting a word-struct \"Word\" " +
			"with a malformed struct tag."
	)

	var (
		e error
	)

	e = NewWordWithMalformedTagError(functionName, formatName, wordName)

	assert.Equal(t,
		errorMessage, e.Error(),
	)
}
