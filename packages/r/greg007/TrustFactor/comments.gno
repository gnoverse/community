package trustfactor

import (
	"chain/runtime"
	"time"

	"gno.land/p/nt/avl"
)

// =============================================================================
// COMMENT FUNCTIONS
// =============================================================================

// AddComment adds a comment to a user's profile
func AddComment(cur realm, target address, text string) {
	caller := runtime.OriginCaller()

	// Verify caller is registered
	if !trustScores.Has(string(caller)) {
		panic("commenter must be registered")
	}

	// Verify target exists
	if !trustScores.Has(string(target)) {
		panic("target user not registered")
	}

	// Validate comment text
	if len(text) == 0 {
		panic("comment text cannot be empty")
	}
	if len(text) > 500 {
		panic("comment text too long (max 500 characters)")
	}

	// Initialize AVL tree for target if not exists
	var targetTree *avl.Tree
	if treeValue, exists := userComments.Get(string(target)); exists {
		targetTree = treeValue.(*avl.Tree)
	} else {
		targetTree = avl.NewTree()
		userComments.Set(string(target), targetTree)
	}

	// Create comment
	comment := Comment{
		Author:    caller,
		Text:      text,
		Timestamp: time.Now().Unix(),
	}

	// Use timestamp + author as unique key
	key := string(comment.Timestamp) + "_" + string(caller)
	targetTree.Set(key, comment)
}

// GetComments returns all comments for a user's profile
func GetComments(target address) []Comment {
	treeValue, exists := userComments.Get(string(target))
	if !exists {
		return []Comment{}
	}
	tree := treeValue.(*avl.Tree)

	comments := make([]Comment, 0)
	tree.ReverseIterate("", "", func(key string, value any) bool {
		if comment, ok := value.(Comment); ok {
			comments = append(comments, comment)
		}
		return false
	})

	return comments
}

// GetCommentCount returns the number of comments for a user
func GetCommentCount(target address) int {
	treeValue, exists := userComments.Get(string(target))
	if !exists {
		return 0
	}
	tree := treeValue.(*avl.Tree)
	return tree.Size()
}
