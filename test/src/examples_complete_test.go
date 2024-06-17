package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/logger"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/eks"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/client-go/informers"
	"k8s.io/client-go/tools/cache"
)

func testExamplesComplete(t *testing.T, terraformOptions *terraform.Options, randID string, _ string) {

	// Run `terraform output` to get the value of an output variable
	vpcCidr := terraform.Output(t, terraformOptions, "vpc_cidr")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "172.16.0.0/16", vpcCidr)

	// Run `terraform output` to get the value of an output variable
	privateSubnetCidrs := terraform.OutputList(t, terraformOptions, "private_subnet_cidrs")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, []string{"172.16.0.0/19", "172.16.32.0/19"}, privateSubnetCidrs)

	// Run `terraform output` to get the value of an output variable
	publicSubnetCidrs := terraform.OutputList(t, terraformOptions, "public_subnet_cidrs")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, []string{"172.16.96.0/19", "172.16.128.0/19"}, publicSubnetCidrs)

	// Run `terraform output` to get the value of an output variable
	eksClusterId := terraform.Output(t, terraformOptions, "eks_cluster_id")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-eks-node-group-"+randID+"-cluster", eksClusterId)

	// Run `terraform output` to get the value of an output variable
	eksNodeGroupId := terraform.Output(t, terraformOptions, "eks_node_group_id")
	eksNodeGroupCbdPetName := terraform.Output(t, terraformOptions, "eks_node_group_cbd_pet_name")
	expectedEksNodeGroupId := "eg-test-eks-node-group-" + randID + "-cluster:eg-test-eks-node-group-" + randID + "-workers-" + eksNodeGroupCbdPetName
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedEksNodeGroupId, eksNodeGroupId)

	// Run `terraform output` to get the value of an output variable
	eksNodeGroupRoleName := terraform.Output(t, terraformOptions, "eks_node_group_role_name")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-eks-node-group-"+randID+"-workers", eksNodeGroupRoleName)

	// Run `terraform output` to get the value of an output variable
	eksNodeGroupStatus := terraform.Output(t, terraformOptions, "eks_node_group_status")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "ACTIVE", eksNodeGroupStatus)

	// Wait for the worker nodes to join the cluster
	// https://github.com/kubernetes/client-go
	// https://www.rushtehrani.com/post/using-kubernetes-api
	// https://rancher.com/using-kubernetes-api-go-kubecon-2017-session-recap
	// https://gianarb.it/blog/kubernetes-shared-informer
	// https://stackoverflow.com/questions/60547409/unable-to-obtain-kubeconfig-of-an-aws-eks-cluster-in-go-code/60573982#60573982
	fmt.Println("Waiting for worker nodes to join the EKS cluster")

	clusterName := "eg-test-eks-node-group-" + randID + "-cluster"
	region := "us-east-2"

	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	}))

	eksSvc := eks.New(sess)

	input := &eks.DescribeClusterInput{
		Name: aws.String(clusterName),
	}

	result, err := eksSvc.DescribeCluster(input)
	if !assert.NoError(t, err) {
		t.Fatal("Unable to find the EKS cluster, skipping any further tests")
	}

	clientset, err := newClientset(result.Cluster)
	if !assert.NoError(t, err) {
		t.Fatal("Unable to create a client for the EKS cluster, skipping any further tests")
	}

	factory := informers.NewSharedInformerFactory(clientset, 0)
	informer := factory.Core().V1().Nodes().Informer()
	stopChannel := make(chan struct{})
	var countOfWorkerNodes uint64 = 0
	var expectedCountOfWorkerNodes uint64 = 4
	var allWorkerNodesJoined bool = false

	if !assert.NotNil(t, informer, "Unable to create a node informer") {
		t.Fatal("Unable to create a node informer, skipping any further tests")
	}
	informer.AddEventHandler(cache.ResourceEventHandlerFuncs{
		AddFunc: func(obj interface{}) {
			node := obj.(*corev1.Node)
			fmt.Printf("Worker Node %s has joined the EKS cluster at %s\n", node.Name, node.CreationTimestamp)
			atomic.AddUint64(&countOfWorkerNodes, 1)
			if countOfWorkerNodes >= expectedCountOfWorkerNodes {
				allWorkerNodesJoined = true
				close(stopChannel)
			}
		},
	})

	var wg sync.WaitGroup
	wg.Add(1) // We're waiting for one goroutine (the informer)

	go func() {
		informer.Run(stopChannel)
		wg.Done() // Call Done on the WaitGroup when the informer is finished
	}()

	select {
	case <-stopChannel:
		msg := "All worker nodes have joined the EKS cluster"
		fmt.Println(msg)
	case <-time.After(5 * time.Minute):
		msg := "Not all worker nodes have joined the EKS cluster"
		fmt.Println(msg)
		assert.Fail(t, msg)
	}

	wg.Wait() // Wait for all goroutines to finish

	if !allWorkerNodesJoined {
		return
	}

	hasLabel := checkSomeNodeHasLabel(clientset, "terratest", "true")
	assert.True(t, hasLabel, "No node with label terratest=true found in the cluster")

	hasLabel = checkSomeNodeHasLabel(clientset, "attributes", randID)
	assert.True(t, hasLabel, "No node with label attributes=%s found in the cluster", randID)

	hasTaint := checkSomeNodeHasTaint(clientset, "test", "", corev1.TaintEffectPreferNoSchedule)
	assert.True(t, hasTaint, "No node with taint test=:PreferNoSchedule found in the cluster")

}

// To speed up debugging, allow running the tests on an existing cluster,
// without creating and destroying one.
// Run this manually by creating a cluster in examples/complete with:
//
//	export EXISTING_CLUSTER_ATTRIBUTE="<your-name>"
//	terraform apply -var-file fixtures.us-east-2.tfvars -var "attributes=[\"$EXISTING_CLUSTER_ATTRIBUTE\"]"
func Test_ExistingCluster(t *testing.T) {
	randID := strings.ToLower(os.Getenv("EXISTING_CLUSTER_ATTRIBUTE"))
	if randID == "" {
		t.Skip("(This is normal): EXISTING_CLUSTER_ATTRIBUTE is not set, skipping...")
		return
	}

	attributes := []string{randID}

	varFiles := []string{"fixtures.us-east-2.tfvars"}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// Keep the output quiet
	if !testing.Verbose() {
		terraformOptions.Logger = logger.Discard
	}

	testExamplesComplete(t, terraformOptions, randID, "")
}
