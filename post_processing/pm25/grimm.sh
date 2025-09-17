
pre:
tr -d '\r' < input.grimm | sed 's|  *|,|g' > input_fixed.grimm

post:
sed 's|-1||g'

