package nftregistry

// Query functions for frontend or marketplaces

// GetAllCollections - Returns all registered collections
func GetAllCollections() []CollectionInfo {
	result := make([]CollectionInfo, 0, GetTotalCollections())

	collections.Iterate("", "", func(key string, value interface{}) bool {
		info := value.(*CollectionInfo)
		result = append(result, *info)
		return false
	})

	return result
}

// GetVerifiedCollections - Returns only verified collections
func GetVerifiedCollections() []CollectionInfo {
	result := make([]CollectionInfo, 0, GetVerifiedCount())

	collections.Iterate("", "", func(key string, value interface{}) bool {
		info := value.(*CollectionInfo)
		if info.Verified {
			result = append(result, *info)
		}
		return false
	})

	return result
}

// GetCollectionsByCategory - Returns collections in a specific category
func GetCollectionsByCategory(category string) []CollectionInfo {
	result := make([]CollectionInfo, 0)

	collections.Iterate("", "", func(key string, value interface{}) bool {
		info := value.(*CollectionInfo)
		if info.Category == category {
			result = append(result, *info)
		}
		return false
	})

	return result
}
