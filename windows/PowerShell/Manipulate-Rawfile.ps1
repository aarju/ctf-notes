# http://www.fuzzysecurity.com/tutorials/20.html

########
# The idea is that you can modify the PE entry point so it loads your shellcode
########

#read the file into an array
$read = [System.IO.File]::ReadAllBytes('C:\test.bin')

# manually assign values to the array elements
$read[2] = 255  # set it to 0xff
$read[3] = 0xff # set it to 0xff

#read the values in the array and print it as hex
'0x{0}' -f ((($read[0..3]) | % {$_.ToString('X2')}) -join '')

# write the changes
[System.IO.File]::WriteAllBytes('C:\test.bin', $read)


########
# editing a PE file
########

# Read entire PE array into memory
$bytes = [System.IO.File]::ReadAllBytes('C:\Users\b33f\Desktop\notepad++.exe')
 
# PE Header offset at 0x3c (60-byes), little endian!
$PEOffset = [Int32] ('0x{0}' -f (($bytes[63..60] | % {$_.ToString('X2')}) -join ''))
echo "PE Header Offset: $PEOffset"
 
# Optional Header = PE Header + 0x18 (24-bytes)
$OptOffset = $PEOffset + 24
echo "Optional Header Offset: $OptOffset"
 
# Module Entry Point = Optional Header + 0x14 (20-bytes)
$EntryPoint = '0x{0}' -f ((($bytes[($OptOffset+19)..($OptOffset+16)]) | % {$_.ToString('X2')}) -join '')
echo "Original Entry Point Offset: $EntryPoint"
 
$bytes[$OptOffset+19] = 0xAA
$bytes[$OptOffset+18] = 0xBB
$bytes[$OptOffset+17] = 0xCC
$bytes[$OptOffset+16] = 0xDD
 
# Fetch New Entry Point
$EntryPoint = '0x{0}' -f ((($bytes[($OptOffset+19)..($OptOffset+16)]) | % {$_.ToString('X2')}) -join '')
echo "New Entry Point Offset: $EntryPoint"
 
# Overwrite the PE with the modified array
[System.IO.File]::WriteAllBytes('C:\Users\b33f\Desktop\notepad++.exe', $bytes)
