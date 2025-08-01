package utils

import (
	"fmt"
	"strconv"
	"time"

	"golang.org/x/crypto/bcrypt"
)

// HashPassword hashes a password using bcrypt
func HashPassword(password string) (string, error) {
	hashedBytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hashedBytes), nil
}

// CheckPassword compares a password with its hash
func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// GenerateCode generates a unique code with prefix and timestamp
func GenerateCode(prefix string) string {
	timestamp := time.Now().Format("20060102150405")
	return fmt.Sprintf("%s%s", prefix, timestamp)
}

// GenerateInvoiceNumber generates a unique invoice number
func GenerateInvoiceNumber(transactionType string) string {
	now := time.Now()
	return fmt.Sprintf("%s%s%03d", 
		transactionType, 
		now.Format("20060102"), 
		now.Second()*10+now.Nanosecond()%1000/100,
	)
}

// CalculateHPP calculates Harga Pokok Penjualan (Cost of Goods Sold)
func CalculateHPP(purchasePrice, repairCost float64) float64 {
	return purchasePrice + repairCost
}

// CalculateProfit calculates profit from selling price and HPP
func CalculateProfit(sellingPrice, hppPrice float64) float64 {
	return sellingPrice - hppPrice
}

// ParseStringToInt safely converts string to int
func ParseStringToInt(s string) (int, error) {
	if s == "" {
		return 0, nil
	}
	return strconv.Atoi(s)
}

// ParseStringToFloat safely converts string to float64
func ParseStringToFloat(s string) (float64, error) {
	if s == "" {
		return 0, nil
	}
	return strconv.ParseFloat(s, 64)
}

// GetPaginationOffset calculates offset for pagination
func GetPaginationOffset(page, limit int) int {
	if page <= 0 {
		page = 1
	}
	return (page - 1) * limit
}

// FormatCurrency formats number as currency string
func FormatCurrency(amount float64) string {
	return fmt.Sprintf("Rp %.2f", amount)
}

// IsValidEnum checks if a value is valid for an enum
func IsValidEnum(value string, validValues []string) bool {
	for _, v := range validValues {
		if v == value {
			return true
		}
	}
	return false
}