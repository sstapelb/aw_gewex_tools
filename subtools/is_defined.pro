;------------------------------------------------------------------------------------------
function is_defined, keyword
	return, (size(keyword,/type) < 1)
end
