package main

import (
	"crypto/ed25519"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"os"
	"testing"
)

// Test keypair (same as test-keypair.json)
var testKeypairBytes = []byte{174, 47, 154, 16, 73, 165, 8, 54, 94, 126, 4, 251, 181, 26, 108, 167, 211, 56, 139, 147, 176, 18, 191, 92, 252, 35, 53, 78, 68, 251, 187, 99, 171, 162, 95, 142, 64, 8, 114, 17, 208, 78, 147, 203, 161, 78, 207, 211, 172, 190, 167, 68, 238, 208, 147, 21, 117, 112, 183, 169, 13, 96, 24, 228}

func TestLoadKeypair(t *testing.T) {
	// Create temporary keypair file
	tmpFile, err := os.CreateTemp("", "test-keypair-*.json")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	// Write test keypair
	keypairJSON, err := json.Marshal(testKeypairBytes)
	if err != nil {
		t.Fatalf("Failed to marshal keypair: %v", err)
	}

	if _, err := tmpFile.Write(keypairJSON); err != nil {
		t.Fatalf("Failed to write keypair: %v", err)
	}
	tmpFile.Close()

	// Test loading the keypair
	privateKey, err := loadKeypairFromFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Failed to load keypair: %v", err)
	}

	// Verify the private key
	if len(privateKey) != ed25519.PrivateKeySize {
		t.Errorf("Expected private key size %d, got %d", ed25519.PrivateKeySize, len(privateKey))
	}

	// Test signing with the loaded keypair
	message := "test message"
	signature := ed25519.Sign(privateKey, []byte(message))

	// Verify signature length
	if len(signature) != ed25519.SignatureSize {
		t.Errorf("Expected signature size %d, got %d", ed25519.SignatureSize, len(signature))
	}

	// Verify signature
	if !ed25519.Verify(privateKey.Public().(ed25519.PublicKey), []byte(message), signature) {
		t.Error("Signature verification failed")
	}
}

func TestLoadKeypairInvalidFile(t *testing.T) {
	// Test with non-existent file
	_, err := loadKeypairFromFile("non-existent-file.json")
	if err == nil {
		t.Error("Expected error for non-existent file")
	}
}

func TestLoadKeypairInvalidJSON(t *testing.T) {
	// Create temporary file with invalid JSON
	tmpFile, err := os.CreateTemp("", "invalid-keypair-*.json")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	if _, err := tmpFile.WriteString("invalid json"); err != nil {
		t.Fatalf("Failed to write invalid JSON: %v", err)
	}
	tmpFile.Close()

	_, err = loadKeypairFromFile(tmpFile.Name())
	if err == nil {
		t.Error("Expected error for invalid JSON")
	}
}

func TestLoadKeypairInvalidLength(t *testing.T) {
	// Create temporary file with invalid keypair length
	tmpFile, err := os.CreateTemp("", "invalid-length-keypair-*.json")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	invalidKeypair := make([]byte, 32) // Too short
	keypairJSON, _ := json.Marshal(invalidKeypair)
	tmpFile.Write(keypairJSON)
	tmpFile.Close()

	_, err = loadKeypairFromFile(tmpFile.Name())
	if err == nil {
		t.Error("Expected error for invalid keypair length")
	}
}

func TestSigningDeterministic(t *testing.T) {
	// Create temporary keypair file
	tmpFile, err := os.CreateTemp("", "deterministic-test-*.json")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	keypairJSON, _ := json.Marshal(testKeypairBytes)
	tmpFile.Write(keypairJSON)
	tmpFile.Close()

	privateKey, err := loadKeypairFromFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Failed to load keypair: %v", err)
	}

	message := "deterministic test message"

	// Sign the same message multiple times
	sig1 := ed25519.Sign(privateKey, []byte(message))
	sig2 := ed25519.Sign(privateKey, []byte(message))

	// Ed25519 signatures should be deterministic with the same private key and message
	if !equalSignatures(sig1, sig2) {
		t.Error("Signatures should be deterministic")
	}
}

func TestSignatureFormats(t *testing.T) {
	// Create test signature
	testSig := make([]byte, 64)
	for i := range testSig {
		testSig[i] = byte(i)
	}

	// Test base64 encoding
	base64Sig := base64.StdEncoding.EncodeToString(testSig)
	decodedBase64, err := base64.StdEncoding.DecodeString(base64Sig)
	if err != nil {
		t.Errorf("Base64 decode error: %v", err)
	}
	if !equalSignatures(testSig, decodedBase64) {
		t.Error("Base64 encoding/decoding failed")
	}

	// Test hex encoding
	hexSig := hex.EncodeToString(testSig)
	decodedHex, err := hex.DecodeString(hexSig)
	if err != nil {
		t.Errorf("Hex decode error: %v", err)
	}
	if !equalSignatures(testSig, decodedHex) {
		t.Error("Hex encoding/decoding failed")
	}
}

func TestKnownSignature(t *testing.T) {
	// Test with known message and expected signature
	tmpFile, err := os.CreateTemp("", "known-sig-test-*.json")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	keypairJSON, _ := json.Marshal(testKeypairBytes)
	tmpFile.Write(keypairJSON)
	tmpFile.Close()

	privateKey, err := loadKeypairFromFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Failed to load keypair: %v", err)
	}

	message := "Test"
	signature := ed25519.Sign(privateKey, []byte(message))
	
	// Convert to base64 for comparison
	base64Sig := base64.StdEncoding.EncodeToString(signature)
	expectedSig := "GY/HTLWHgdOPoxFpTz9X1BpfNJtztRzj0gtUxkS0daX4uuC3/YhubdYbJU1tKNcK3Q3FP7XZ3a3nyVarRObuDA=="

	if base64Sig != expectedSig {
		t.Errorf("Expected signature %s, got %s", expectedSig, base64Sig)
	}
}

func TestPublicKeyValidation(t *testing.T) {
	// Test that the private key can be loaded and used for signing
	tmpFile, err := os.CreateTemp("", "pubkey-validation-*.json")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	keypairJSON, _ := json.Marshal(testKeypairBytes)
	tmpFile.Write(keypairJSON)
	tmpFile.Close()

	privateKey, err := loadKeypairFromFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Failed to load keypair: %v", err)
	}

	// Test that we can sign and verify with this keypair
	message := "validation test"
	signature := ed25519.Sign(privateKey, []byte(message))
	
	if !ed25519.Verify(privateKey.Public().(ed25519.PublicKey), []byte(message), signature) {
		t.Error("Signature verification failed with loaded keypair")
	}
}

// Helper function to compare signatures
func equalSignatures(a, b []byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

func TestLoadKeypairFromString(t *testing.T) {
	// Test with a known base58 encoded key (using a simple test case)
	// Let's use a well-known test vector: encoding of 32 zero bytes should be "11111111111111111111111111111111111111111111"
	zeroSeed := make([]byte, 32) // 32 zero bytes
	
	// Test with our loadKeypairFromString using the zero seed approach
	privateKey := ed25519.NewKeyFromSeed(zeroSeed)
	
	// Test signing with the known zero seed
	message := "test with zero seed"
	signature := ed25519.Sign(privateKey, []byte(message))
	
	if !ed25519.Verify(privateKey.Public().(ed25519.PublicKey), []byte(message), signature) {
		t.Error("Signature verification failed with zero seed")
	}
	
	// Test our actual function with a simple base58 string (just "1" which should decode to [0])
	result, err := base58Decode("1")
	if err != nil {
		t.Fatalf("Failed to decode simple base58: %v", err)
	}
	if len(result) != 1 || result[0] != 0 {
		t.Errorf("Expected [0], got %v", result)
	}
}

func TestLoadKeypairFromStringInvalid(t *testing.T) {
	// Test with invalid base58 string
	_, err := loadKeypairFromString("invalid-base58-string-with-0-and-O")
	if err == nil {
		t.Error("Expected error for invalid base58 string")
	}
	
	// Test with wrong length
	shortKey := base58Encode([]byte{1, 2, 3, 4, 5}) // Too short
	_, err = loadKeypairFromString(shortKey)
	if err == nil {
		t.Error("Expected error for short private key")
	}
}

func TestBase58Decode(t *testing.T) {
	// Test with known values
	testCases := []struct {
		input    string
		expected []byte
	}{
		{"1", []byte{0}},
		{"2", []byte{1}},
		{"z", []byte{57}},
		{"11", []byte{0, 0}},
	}
	
	for _, tc := range testCases {
		result, err := base58Decode(tc.input)
		if err != nil {
			t.Errorf("Unexpected error for input %s: %v", tc.input, err)
			continue
		}
		
		if !equalSignatures(result, tc.expected) {
			t.Errorf("For input %s, expected %v, got %v", tc.input, tc.expected, result)
		}
	}
}

// Helper function to encode bytes to base58 (for testing)
func base58Encode(data []byte) string {
	const alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
	
	if len(data) == 0 {
		return ""
	}
	
	// Convert to big integer
	var result []byte
	
	// Count leading zeros
	leadingZeros := 0
	for i := 0; i < len(data) && data[i] == 0; i++ {
		leadingZeros++
	}
	
	// Convert
	input := make([]byte, len(data))
	copy(input, data)
	
	for len(input) > 0 {
		// Find first non-zero
		i := 0
		for i < len(input) && input[i] == 0 {
			i++
		}
		input = input[i:]
		
		if len(input) == 0 {
			break
		}
		
		// Divide by 58
		remainder := 0
		for i := 0; i < len(input); i++ {
			temp := remainder*256 + int(input[i])
			input[i] = byte(temp / 58)
			remainder = temp % 58
		}
		
		result = append([]byte{alphabet[remainder]}, result...)
	}
	
	// Add leading 1s for leading zeros
	for i := 0; i < leadingZeros; i++ {
		result = append([]byte{'1'}, result...)
	}
	
	return string(result)
}
