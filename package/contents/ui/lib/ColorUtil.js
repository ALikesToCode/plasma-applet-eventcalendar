.pragma library
// Version: 2

// https://stackoverflow.com/questions/9733288/how-to-programmatically-calculate-the-contrast-ratio-between-two-colors
// https://www.w3.org/TR/AERT/#color-contrast
function _safeColor(c, fallback) {
	if (c && c.r !== undefined && c.g !== undefined && c.b !== undefined) {
		return c
	}
	if (fallback && fallback.r !== undefined && fallback.g !== undefined && fallback.b !== undefined) {
		return fallback
	}
	return Qt.rgba(0, 0, 0, 1)
}

function brightness(c) {
	c = _safeColor(c)
	return (c.r*299 + c.g*587 + c.b*114) / 1000
}

// https://www.w3.org/TR/AERT/#color-contrast
function contrast(c1, c2) {
	c1 = _safeColor(c1, c2)
	c2 = _safeColor(c2, c1)
	return Math.max(c1.r, c2.r) - Math.min(c1.r, c2.r) + Math.max(c1.g, c2.g) - Math.min(c1.g, c2.g) + Math.max(c1.b, c2.b) - Math.min(c1.b, c2.b)
}

// https://www.w3.org/TR/AERT/#color-contrast
// w3 mentions 500 using rgb 255 values. QML rgba is 0..1 however, and 500/255=1.96
function hasEnoughContrast(c1, c2) {
	return contrast(c1, c2) >= 1.96
}

function setAlpha(c, a) {
	c = _safeColor(c)
	return Qt.rgba(c.r, c.g, c.b, a)
}

function _interpolate(a, b, t) {
	return (a - b) * t + b
}
// Linear Interpolation from color1 to color2 by a ratio of t.
function lerp(c1, c2, t) {
	c1 = _safeColor(c1, c2)
	c2 = _safeColor(c2, c1)
	var r = _interpolate(c1.r, c2.r, t)
	var g = _interpolate(c1.g, c2.g, t)
	var b = _interpolate(c1.b, c2.b, t)
	var a = _interpolate(c1.a, c2.a, t)
	return Qt.rgba(r, g, b, a)
}
