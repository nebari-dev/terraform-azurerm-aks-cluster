package test

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

const fixtureDir = "../examples/complete"

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
		Reconfigure: true,
	}

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

	backupStorageAccount := terraform.Output(t, terraformOptions, "longhorn_backup_storage_account_name")
	if backupStorageAccount == "" {
		t.Fatal("longhorn_backup_storage_account_name output is empty")
	}
	t.Logf("longhorn_backup_storage_account_name=%s", backupStorageAccount)

	backupContainer := terraform.Output(t, terraformOptions, "longhorn_backup_container_name")
	if backupContainer == "" {
		t.Fatal("longhorn_backup_container_name output is empty")
	}
	t.Logf("longhorn_backup_container_name=%s", backupContainer)

	kubeconfigPath := writeKubeconfig(t, terraformOptions)
	defer os.Remove(kubeconfigPath)

	testManagedDiskCSI(t, kubeconfigPath)
}

func writeKubeconfig(t *testing.T, opts *terraform.Options) string {
	kubeconfig := terraform.Output(t, opts, "kube_config_raw")
	if kubeconfig == "" {
		t.Fatal("kube_config_raw is empty")
	}
	f, err := os.CreateTemp("", "nebari-test-kubeconfig-*.yaml")
	if err != nil {
		t.Fatalf("create temp kubeconfig: %v", err)
	}
	if _, err := f.WriteString(kubeconfig); err != nil {
		t.Fatalf("write kubeconfig: %v", err)
	}
	f.Close()
	return f.Name()
}

func testManagedDiskCSI(t *testing.T, kubeconfigPath string) {
	kubectl := k8s.NewKubectlOptions("", kubeconfigPath, "default")

	k8s.KubectlApply(t, kubectl, "fixtures/disk-csi/storageclass.yaml")
	defer k8s.KubectlDelete(t, kubectl, "fixtures/disk-csi/storageclass.yaml")

	k8s.KubectlApply(t, kubectl, "fixtures/disk-csi/pvc.yaml")
	defer k8s.KubectlDelete(t, kubectl, "fixtures/disk-csi/pvc.yaml")

	k8s.KubectlApply(t, kubectl, "fixtures/disk-csi/pod.yaml")
	defer k8s.KubectlDelete(t, kubectl, "fixtures/disk-csi/pod.yaml")

	k8s.WaitUntilPodAvailable(t, kubectl, "test-pod", 30, 10*time.Second)
}

func getEnvOrDefault(key, defaultValue string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultValue
}

func writeTestOverride(path string) error {
	content := `{
  "module": {
    "aks_cluster": {
      "node_groups": {
        "system": {
          "vm_size":   "Standard_D2_v3",
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
