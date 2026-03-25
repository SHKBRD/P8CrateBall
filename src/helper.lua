--helper
function lerp(v1, v2, percent)
	return (v1 + (v2-v1)*percent)
end

--function ilerp(v1, v2, inter)
--	return (inter-v1)/(v2-v1)
--end

function distance(x1,y1,x2,y2)
	return sqrt(((x2-x1)^2 + (y2-y1)^2))
end

function round(num)
	return flr(num+0.5)
end