/^Package:/{
s/^Package:[[:space:]]*\<\([a-z0-9.+-]*$1[a-z0-9.+-]*\).*/\1/
h
}
/^Description:/{
s/^Description:[[:space:]]*\(.*\)/\1/
H
g
s/\\
/ - /
p
}