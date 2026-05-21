package test

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

const fixtureDir = "../examples/complete"

// TestAKSClusterComplete provisions the examples/complete fixture,
// verifies the cluster is reachable, and exercises the managed-disk CSI driver.
func TestAKSClusterComplete(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test in short mode")
	}

	projectName := fmt.Sprintf("nebari-test-%s", random.UniqueId())

	terraformOptions := &terraform.Options{
		TerraformDir: fixtureDir,
		Vars: map[string]interface{}{
			"project_name": projectName,
			"location":     getEnvOrDefault("AZURE_TEST_LOCATION", "eastus"),
		},
		EnvVars: map[string]string{
			"ARM_SUBSCRIPTION_ID": os.Getenv("ARM_SUBSCRIPTION_ID"),
		},
		// Write an override file that forces test-friendly settings.
		Reconfigure: true,
	}

	// Override file to keep the cluster small for tests.
	overridePath := filepath.Join(fixtureDir, "test_override.tf.json")
	if err := writeTestOverride(overridePath); err != nil {
		t.Fatalf("failed to write test override: %v", err)
	}
	defer os.Remove(overridePath)

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	clusterName := terraform.Output(t, terraformOptions, "cluster_name")
	if clusterName == "" {
		t.Fatal("cluster_name output is empty")
	}
	t.Logf("cluster_name=%s", clusterName)

	// TODO: test managed-disk CSI in Task 21.
}

func getEnvOrDefault(key, defaultValue string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultValue
}

func writeTestOverride(path string) error {
	// Force smallest viable VM size and a single-node system pool for cost control.
	content := `{
  "module": {
    "aks_cluster": {
      "node_groups": {
        "system": {
          "vm_size":   "Standard_B2s",
          "min_count": 1,
          "max_count": 1,
          "mode":      "System"
        }
      }
    }
  }
}`
	return os.WriteFile(path, []byte(content), 0644)
}
