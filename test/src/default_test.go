package test

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"regexp"
	"testing"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()

	testRunner(t, nil, testExamplesComplete)
}

func TestExamplesCompleteDisabled(t *testing.T) {
	t.Parallel()

	vars := &map[string]interface{}{
		"enabled": false,
	}
	testRunner(t, vars, testExamplesCompleteDisabled)
}

func testExamplesCompleteDisabled(t *testing.T, terraformOptions *terraform.Options, randID string, results string) {
	// Should complete successfully without creating or changing any resources.
	// Extract the "Resources:" section of the output to make the error message more readable.
	re := regexp.MustCompile(`Resources: [^.]+\.`)
	match := re.FindString(results)
	assert.Equal(t, "Resources: 0 added, 0 changed, 0 destroyed.", match, "Re-applying the same configuration should not change any resources")
}
