package test

import (
	"fmt"
	"sync/atomic"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/cache"
	"k8s.io/client-go/tools/clientcmd"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

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
	assert.Equal(t, "eg-test-eks-node-group-cluster", eksClusterId)

	// Run `terraform output` to get the value of an output variable
	eksNodeGroupId := terraform.Output(t, terraformOptions, "eks_node_group_id")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-eks-node-group-cluster:eg-test-eks-node-group-workers", eksNodeGroupId)

	// Run `terraform output` to get the value of an output variable
	eksNodeGroupRoleName := terraform.Output(t, terraformOptions, "eks_node_group_role_name")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-eks-node-group-workers", eksNodeGroupRoleName)

	// Run `terraform output` to get the value of an output variable
	eksNodeGroupStatus := terraform.Output(t, terraformOptions, "eks_node_group_status")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "ACTIVE", eksNodeGroupStatus)

	// Wait for the worker nodes from Node Group to join the cluster
	// https://github.com/kubernetes/client-go
	// https://www.rushtehrani.com/post/using-kubernetes-api
	// https://rancher.com/using-kubernetes-api-go-kubecon-2017-session-recap
	// https://gianarb.it/blog/kubernetes-shared-informer
	fmt.Println("Waiting for worker nodes from Node Group to join the EKS cluster")

	kubeconfigPath := "/.kube/config"
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfigPath)
	assert.NoError(t, err)

	clientset, err := kubernetes.NewForConfig(config)
	assert.NoError(t, err)

	factory := informers.NewSharedInformerFactory(clientset, 0)
	informer := factory.Core().V1().Nodes().Informer()
	stopChannel := make(chan struct{})
	var countOfWorkerNodes uint64 = 0

	informer.AddEventHandler(cache.ResourceEventHandlerFuncs{
		AddFunc: func(obj interface{}) {
			node := obj.(*corev1.Node)
			fmt.Printf("Worker Node %s has joined the EKS cluster at %s\n", node.Name, node.CreationTimestamp)
			atomic.AddUint64(&countOfWorkerNodes, 1)
			if countOfWorkerNodes > 1 {
				close(stopChannel)
			}
		},
	})

	go informer.Run(stopChannel)

	select {
	case <-stopChannel:
		msg := "All worker nodes from Node Group have joined the EKS cluster"
		fmt.Println(msg)
	case <-time.After(5 * time.Minute):
		msg := "Not all worker nodes from Node Group have joined the EKS cluster"
		fmt.Println(msg)
		assert.Fail(t, msg)
	}
}
