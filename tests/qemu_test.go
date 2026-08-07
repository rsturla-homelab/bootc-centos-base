package tests

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/ssh"
)

var (
	SSH_PRIVATE_KEY = os.Getenv("SSH_PRIVATE_KEY")
	SSH_PORT        = os.Getenv("SSH_PORT")
)

type SSHCommandTest struct {
	Name         string
	Command      string
	ExpectedText string
}

func getSharedHost() ssh.Host {
	port := 2222
	if SSH_PORT != "" {
		fmt.Sscanf(SSH_PORT, "%d", &port)
	}
	return ssh.Host{
		Hostname:    "localhost",
		SshKeyPair:  &ssh.KeyPair{PrivateKey: SSH_PRIVATE_KEY},
		CustomPort:  port,
		SshUserName: "ci-user",
	}
}

func runSSHCommandTest(t *testing.T, host ssh.Host, test SSHCommandTest) {
	t.Run(test.Name, func(t *testing.T) {
		t.Parallel()

		maxRetries := 2
		timeBetweenRetries := 5 * time.Second

		retry.DoWithRetry(t, test.Name, maxRetries, timeBetweenRetries, func() (string, error) {
			output, err := ssh.CheckSshCommandE(t, host, test.Command)
			if err != nil {
				return "", fmt.Errorf("SSH command failed: %v", err)
			}
			if !strings.Contains(output, test.ExpectedText) {
				return "", fmt.Errorf("Expected output to contain '%s', but got '%s'", test.ExpectedText, output)
			}
			return output, nil
		})
	})
}

func TestQemuSSHCommands(t *testing.T) {
	host := getSharedHost()

	tests := []SSHCommandTest{
		{
			Name:         "KernelInstalled",
			Command:      "rpm -q kernel",
			ExpectedText: "kernel",
		},
		{
			Name:         "CheckSELinuxStatus",
			Command:      "getenforce",
			ExpectedText: "Enforcing",
		},
		{
			Name:         "CheckSudoersValid",
			Command:      "sudo visudo -cf /etc/sudoers",
			ExpectedText: "/etc/sudoers: parsed OK",
		},
		{
			Name:         "CheckNftablesServiceEnabled",
			Command:      "systemctl is-enabled nftables",
			ExpectedText: "enabled",
		},
		{
			Name:         "CheckNftablesServiceActive",
			Command:      "systemctl is-active nftables",
			ExpectedText: "active",
		},
	}

	for _, test := range tests {
		runSSHCommandTest(t, host, test)
	}
}
