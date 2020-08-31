MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript
Content-Type: charset="us-ascii"

${before_cluster_joining_userdata}

cat << 'EOF' > /etc/eks/extra_args.sh
#!/usr/bin/env bash
set -ex +u

function prepare_lines() {
  local KUBELET_EXTRA_ARGS="$1"

  # Break each argument into its own line, and replace the first '=' with '%' for easier processing later
  # Example output:
  # --register-with-taints%dedicated=test:NoSchedule
  # --node-labels%eks.amazonaws.com/nodegroup=test-mng,other.label=other
  #
  local EXTRA_ARGS_LINES=$(echo "$KUBELET_EXTRA_ARGS" | xargs -d' ' -I{} bash -c 'echo "{}" | sed "0,/=/s//%/"')

  # Remove blank lines
  # Example output:
  # --register-with-taints%dedicated=test:NoSchedule
  # --node-labels%eks.amazonaws.com/nodegroup=test-mng,other.label=other
  local EXTRA_ARGS_LINES=$(echo "$EXTRA_ARGS_LINES" | sed '/^$/d')

  echo "$EXTRA_ARGS_LINES"
}

# 30-kubelet-extra-args.conf example:
# [Service]
# Environment='KUBELET_EXTRA_ARGS=--register-with-taints="dedicated=test:NoSchedule" --node-labels=eks.amazonaws.com/nodegroup=test-mng,other.label=other'

# Get the last line and cut out the part between the single quotes
# Example output:
# KUBELET_EXTRA_ARGS=--register-with-taints="dedicated=test:NoSchedule" --node-labels=eks.amazonaws.com/nodegroup=test-mng,other.label=other
ENVIRONMENT=$(tail -n1 /etc/systemd/system/kubelet.service.d/30-kubelet-extra-args.conf | cut -d\' -f2)

# Get the value of KUBELET_EXTRA_ARGS
# Example output:
# --register-with-taints="dedicated=test:NoSchedule" --node-labels=eks.amazonaws.com/nodegroup=test-mng,other.label=other
KUBELET_EXTRA_ARGS=$(echo "$ENVIRONMENT" | cut -d= -f 2-)

# Declare an associate array for later use
declare -A EXTRA_ARGS=()

# Loop over each of the lines and add each key value pair to the associate array
# Example output:
# [--node-labels]="eks.amazonaws.com/nodegroup=test-mng,other.label=other"
# [--register-with-taints]="dedicated=test:NoSchedule"
while IFS=% read -r key value; do
  EXTRA_ARGS[$key]="$value"
done < <(prepare_lines "$KUBELET_EXTRA_ARGS")

# Additional args from Terraform, separated by spaces
# Example:
# --log-file=/tmp/kubelet.log
KUBELET_NEW_ARGS='${kubelet_extra_args}'

if [[ -n "$KUBELET_NEW_ARGS" ]]; then
  # Declare an associate array for later use
  declare -A NEW_EXTRA_ARGS=()

  # Loop over each of the lines and add each key value pair to the associate array
  # Example output:
  # [--log-file]="/tmp/kubelet.log"
  # [--hostname-override]="dedicated-node-az1"
  while IFS=% read -r key value; do
    NEW_EXTRA_ARGS[$key]="$value"
  done < <(prepare_lines "$KUBELET_NEW_ARGS")

  for KEY in "$${!NEW_EXTRA_ARGS[@]}"; do
    # If there is existing values, add a comma before adding the new values
    test -n "$${EXTRA_ARGS[$KEY]}" && EXTRA_ARGS[$KEY]+=","
    EXTRA_ARGS[$KEY]+="$${NEW_EXTRA_ARGS[$KEY]}"
  done
fi

# Additional taints from Terraform, separated by commas
# Example:
# dedicated=new-test:NoSchedule
NEW_TAINTS='${node_taints}'

# Additional labels from Terraform, separated by commas
# Example:
# new.label=new
NEW_LABELS='${node_labels}'

# Add the new taints to the associate array, if defined
# Example output:
# [--node-labels]="eks.amazonaws.com/nodegroup=test-mng,other.label=other"
# [--register-with-taints]="dedicated=test:NoSchedule,dedicated=new-test:NoSchedule"
if [[ -n "$NEW_TAINTS" ]]; then
  # If there is existing taints, add a comma before adding the new taints
  test -n "$${EXTRA_ARGS['--register-with-taints']}" && EXTRA_ARGS['--register-with-taints']+=","
  EXTRA_ARGS['--register-with-taints']+="$NEW_TAINTS"
fi

# Add the new labels to the associate array, if defined
# Example output:
# [--node-labels]="eks.amazonaws.com/nodegroup=test-mng,other.label=other,new.label=new"
# [--register-with-taints]="dedicated=test:NoSchedule,dedicated=new-test:NoSchedule"
if [[ -n "$NEW_LABELS" ]]; then
  # If there is existing labels, add a comma before adding the new labels
  test -n "$${EXTRA_ARGS['--node-labels']}" && EXTRA_ARGS['--node-labels']+=","
  EXTRA_ARGS['--node-labels']+="$NEW_LABELS"
fi

# Build string from the joined arguments to add to the output file
# Example:
# --log-file=/tmp/kubelet.log --hostname-override=dedicated-node-az1 --node-labels=eks.amazonaws.com/nodegroup=test-mng,other.label=other,new.label=new --register-with-taints=dedicated=test:NoSchedule,dedicated=new-test:NoSchedule
NEW_KUBELET_EXTRA_ARGS=""
for i in "$${!EXTRA_ARGS[@]}";do
  NEW_KUBELET_EXTRA_ARGS+=$(printf "%s=%s " "$i" "$${EXTRA_ARGS[$i]}")
done

# Remove the trailing space
NEW_KUBELET_EXTRA_ARGS=$(echo "$NEW_KUBELET_EXTRA_ARGS" | xargs)

# Write the final output file
# Example:
# [Service]
# Environment='KUBELET_EXTRA_ARGS=--log-file=/tmp/kubelet.log --hostname-override=dedicated-node-az1 --node-labels=eks.amazonaws.com/nodegroup=test-mng,other.label=other,new.label=new --register-with-taints=dedicated=test:NoSchedule,dedicated=new-test:NoSchedule'
cat <<CONF > /etc/systemd/system/kubelet.service.d/30-kubelet-extra-args.conf
[Service]
Environment='KUBELET_EXTRA_ARGS=$${NEW_KUBELET_EXTRA_ARGS}'
CONF
EOF

# Execute the hook script before starting the services
sed -i "/^systemctl daemon-reload\$/i . /etc/eks/extra_args.sh" /etc/eks/bootstrap.sh
--//