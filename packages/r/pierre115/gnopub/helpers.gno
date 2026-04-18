package gnopub

func getColorName(color string) string {
	switch color {
	case "#f44336":
		return "Red"
	case "#2196f3":
		return "Blue"
	case "#4caf50":
		return "Green"
	case "#ff9800":
		return "Orange"
	default:
		return "White"
	}
}
