#!/bin/bash -x

# Define file paths
SEALED_SECRET_FILE="statistics-sealed-secret.yaml"
RECOVERED_SECRET_FILE="statistics-recovered-secret.yaml"
SEALED_SECRETS_KEY_YAML_FILE="sealed-secrets-key.yaml"
SEALED_SECRETS_KEY_PEM_FILE="sealed-secrets-key.pem"

# Extract the Sealed Secrets private key (requires admin privileges)
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > $SEALED_SECRETS_KEY_YAML_FILE

# Verify the key file was created
if [ ! -s $SEALED_SECRETS_KEY_YAML_FILE ]; then
    echo "Failed to extract the Sealed Secrets private key"
    exit 1
fi

# Decode the base64-encoded private key to a PEM file
KEY=$(kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o jsonpath="{.items[0].data['tls\.key']}")
echo $KEY | base64 --decode > $SEALED_SECRETS_KEY_PEM_FILE

# Verify the PEM file was created
if [ ! -s $SEALED_SECRETS_KEY_PEM_FILE ]; then
    echo "Failed to create the PEM file from the extracted key"
    exit 1
fi

# Optional: Output the extracted PEM key for debugging
echo "Extracted PEM key:"
cat $SEALED_SECRETS_KEY_PEM_FILE

# Recover the original secret from the sealed secret using the private key
kubeseal --recovery-unseal --recovery-private-key $SEALED_SECRETS_KEY_PEM_FILE -f $SEALED_SECRET_FILE -o yaml > $RECOVERED_SECRET_FILE

# Verify the recovered secret was created
if [ ! -s $RECOVERED_SECRET_FILE ]; then
    echo "Failed to recover the original secret"
    exit 1
fi

# Output the recovered secret
echo "Recovered Secret:"
cat $RECOVERED_SECRET_FILE

# Clean up private key files
rm $SEALED_SECRETS_KEY_YAML_FILE $SEALED_SECRETS_KEY_PEM_FILE
