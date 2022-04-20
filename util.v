[inline]
fn min<T>(a T, b T) T {
	if a < b {
		return a
	} else {
		return b
	}
}

[inline]
fn max<T>(a T, b T) T {
	if a > b {
		return a
	} else {
		return b
	}
}

[inline]
fn clamp<T>(x T, min T, max T) T {
	if x < min {
		return min
	} else if x > max {
		return max
	} else {
		return x
	}
}

[inline]
fn sign<T>(x T) i8 {
	if x < 0 {
		return -1
	} else {
		return 1
	}
}
